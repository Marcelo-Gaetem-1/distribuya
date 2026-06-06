import { LightningElement, api } from 'lwc';

/**
 * productCard — presentational card for one product variant.
 * Uses PRIMITIVE @api props (not a nested object) for robustness across LWR/serialization.
 * Emits `additem` with the productId when the user adds it.
 */
export default class ProductCard extends LightningElement {
    @api productId;
    @api productName;
    @api brand;
    @api familyName;
    @api availableStock;

    quantity = 1;

    get outOfStock() {
        return this.availableStock == null || this.availableStock <= 0;
    }

    handleQtyChange(event) {
        const v = parseInt(event.target.value, 10);
        this.quantity = (isNaN(v) || v < 1) ? 1 : v;
    }

    handleAdd() {
        this.dispatchEvent(new CustomEvent('additem', {
            detail: {
                productId: this.productId,
                name: this.productName,
                quantity: this.quantity
            }
        }));
    }
}
