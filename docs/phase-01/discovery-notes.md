# Phase 1 — Block A: Discovery Notes

Discovery por escenas del proceso de negocio. Cada escena destapa decisiones que después se materializan en el modelo de datos.

## Scene 1 — Order cycle (closed)

| Tema | Decisión |
|---|---|
| Pricing | (c) Base por segmento + override por cliente |
| Aprobación crediticia | Matriz escalonada: comercial 100% → manager 150% → crédito >150% |
| Estado del pedido en aprobación | Interno "Pendiente" / UX "En revisión" |
| Reserva de stock | Con timeout (2-4 horas) |
| Perfil operacional | 500-2000 pedidos/día, stock mixto |
| Condiciones de pago | Mixto: COD para clientes nuevos, Net 15/30/60 según historial |

## Scene 2 — Customer onboarding (closed)

| Tema | Decisión |
|---|---|
| Modelo de cliente multi-local | Padre (entidad legal, crédito, facturación) + sucursales hijas (pedidos) |
| Quién hace el alta | Híbrido: comercial inicia + onboarding valida y activa |
| Condición de pago inicial | COD para clientes nuevos |
| Mix de clientes en la base | ~50% single-location / ~50% multi-sucursal |

## Scene 3 — Catalog and pricing (closed)

| Tema | Decisión |
|---|---|
| Estructura del catálogo | Categorías de un nivel (Alimentos, Bebidas, Limpieza, Empaque...) |
| Variantes | Producto padre con variantes (no productos sueltos) |
| Nivel donde vive el precio | Por variante (no por padre) |
| Descuentos por volumen | Sí, con escalones de cantidad (Price Tiers) |
