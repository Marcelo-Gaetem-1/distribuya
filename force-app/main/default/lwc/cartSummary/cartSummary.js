import { LightningElement, api } from 'lwc';

/**
 * cartSummary — shows cart lines and a Place Order button.
 * Emits `placeorder` (parent calls Apex) and `removeitem`.
 */
export default class CartSummary extends LightningElement {
    @api lines = []; // [{ productId, name, quantity }]
    @api placing = false;

    get isEmpty() {
        return !this.lines || this.lines.length === 0;
    }

    get totalUnits() {
        return (this.lines || []).reduce((sum, l) => sum + Number(l.quantity || 0), 0);
    }

    handleRemove(event) {
        const productId = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('removeitem', { detail: { productId } }));
    }

    handlePlaceOrder() {
        this.dispatchEvent(new CustomEvent('placeorder'));
    }
}
