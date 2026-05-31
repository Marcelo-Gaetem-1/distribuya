import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCatalog from '@salesforce/apex/CatalogController.getCatalog';
import placeOrder from '@salesforce/apex/PortalOrderController.placeOrder';

/**
 * catalogBrowser — B2B portal entry component. Lists the catalog (CatalogController),
 * lets the user build a cart, and places the order (PortalOrderController).
 * The account/branch to order for is passed in via @api accountId (set on the portal page).
 */
export default class CatalogBrowser extends LightningElement {
    @api accountId;            // account/branch the portal user is ordering for
    @track families = [];
    @track cart = [];          // [{ productId, name, quantity }]
    placing = false;
    error;

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
        const { productId, name, quantity } = event.detail;
        const existing = this.cart.find((l) => l.productId === productId);
        if (existing) {
            existing.quantity += quantity;
            this.cart = [...this.cart];
        } else {
            this.cart = [...this.cart, { productId, name, quantity }];
        }
    }

    handleRemoveItem(event) {
        const { productId } = event.detail;
        this.cart = this.cart.filter((l) => l.productId !== productId);
    }

    async handlePlaceOrder() {
        if (!this.accountId) {
            this.toast('Error', 'No account context for this order.', 'error');
            return;
        }
        this.placing = true;
        try {
            const lines = this.cart.map((l) => ({ productId: l.productId, quantity: l.quantity }));
            const orderId = await placeOrder({ accountId: this.accountId, lines });
            this.toast('Order placed', 'Your order has been created.', 'success');
            this.cart = [];
            this.dispatchEvent(new CustomEvent('ordercreated', { detail: { orderId } }));
        } catch (e) {
            this.toast('Could not place order', this.reduceError(e), 'error');
        } finally {
            this.placing = false;
        }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) return error.body.map((e) => e.message).join(', ');
        if (error?.body?.message) return error.body.message;
        return error?.message || 'Unknown error';
    }
}
