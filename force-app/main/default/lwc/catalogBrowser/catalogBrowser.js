import { LightningElement, api, wire, track } from 'lwc';
import getCatalog from '@salesforce/apex/CatalogController.getCatalog';
import placeOrder from '@salesforce/apex/PortalOrderController.placeOrder';
import getMyAccountId from '@salesforce/apex/PortalOrderController.getMyAccountId';

/**
 * catalogBrowser — B2B portal entry component. Lists the catalog (CatalogController),
 * lets the user build a cart, and places the order (PortalOrderController).
 *
 * NOTE: uses inline status messages (not ShowToastEvent) — toasts are NOT supported in
 * LWR / Build-Your-Own Experience sites; they silently no-op there.
 */
export default class CatalogBrowser extends LightningElement {
    @api accountId;            // optional override; if blank, derived from the logged-in user
    @track families = [];
    @track cart = [];          // [{ productId, name, quantity }]
    placing = false;
    error;
    statusMessage;             // inline success/info banner
    statusVariant = 'success';

    @wire(getCatalog)
    wiredCatalog({ data, error }) {
        if (data) {
            this.families = data;
            this.error = undefined;
        } else if (error) {
            this.error = this.reduceError(error);
        }
    }

    get hasCatalog() {
        return this.families && this.families.length > 0;
    }

    get isEmptyCatalog() {
        return !this.error && (!this.families || this.families.length === 0);
    }

    handleAddItem(event) {
        // Copy event.detail values into plain primitives for the cart.
        const pid = event.detail ? String(event.detail.productId || '') : '';
        const pname = event.detail ? String(event.detail.name || '') : '';
        const qtyRaw = event.detail ? Number(event.detail.quantity) : 1;
        const qty = qtyRaw > 0 ? qtyRaw : 1;

        if (!pid) {
            this.setStatus('Could not add item: missing product id.', 'error');
            return;
        }

        const newCart = this.cart.map((l) => ({ ...l }));
        const existing = newCart.find((l) => l.productId === pid);
        if (existing) {
            existing.quantity += qty;
        } else {
            newCart.push({ productId: pid, name: pname, quantity: qty });
        }
        this.cart = newCart;
    }

    handleRemoveItem(event) {
        const { productId } = event.detail;
        this.cart = this.cart.filter((l) => l.productId !== productId);
    }

    async handlePlaceOrder() {
        this.statusMessage = undefined;
        this.placing = true;
        try {
            // Resolve the ordering account robustly at submit time: explicit @api override,
            // else the logged-in user's own account. Awaited here so timing can't race.
            let acctId = this.accountId;
            if (!acctId) {
                acctId = await getMyAccountId();
            }
            if (!acctId) {
                this.setStatus('No account is associated with your user. Contact your administrator.', 'error');
                return;
            }
            const lines = this.cart.map((l) => ({
                productId: String(l.productId),
                quantity: Number(l.quantity)
            }));
            // Send as a JSON string and deserialize in Apex — avoids the unreliable
            // LWC->Apex automatic object-to-wrapper mapping (was arriving empty in LWR).
            const orderId = await placeOrder({ accountId: acctId, linesJson: JSON.stringify(lines) });
            this.cart = [];
            this.setStatus('Order placed successfully (' + orderId + ').', 'success');
            this.dispatchEvent(new CustomEvent('ordercreated', { detail: { orderId } }));
        } catch (e) {
            this.setStatus('Could not place order: ' + this.reduceError(e), 'error');
        } finally {
            this.placing = false;
        }
    }

    setStatus(message, variant) {
        this.statusMessage = message;
        this.statusVariant = variant;
    }

    get statusClass() {
        const base = 'slds-notify slds-notify_alert slds-m-bottom_small slds-theme_';
        return base + (this.statusVariant === 'error' ? 'error' : 'success');
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) return error.body.map((e) => e.message).join(', ');
        if (error?.body?.message) return error.body.message;
        return error?.message || 'Unknown error';
    }
}
