import { LightningElement, api } from 'lwc';

/**
 * productCard — presentational card for a single product variant.
 * Emits an `additem` event when the user adds it to the cart.
 */
export default class ProductCard extends LightningElement {
    @api product;     // { id, name, availableStock }
    @api familyName;
    @api brand;

    quantity = 1;

    get outOfStock() {
        return !this.product || this.product.availableStock <= 0;
    }

    handleQtyChange(event) {
        this.quantity = parseInt(event.target.value, 10) || 1;
    }

    handleAdd() {
        this.dispatchEvent(new CustomEvent('additem', {
            detail: { productId: this.product.productId, name: this.product.name, quantity: this.quantity }
        }));
    }
}
