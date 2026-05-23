# Picklist vs Custom Object — Decision Framework

5 preguntas para decidir entre **picklist** y **Custom Object** cuando aparece la necesidad de "categorizar" algo:

| # | Pregunta | Si la respuesta es... | Inclina hacia... |
|---|---|---|---|
| 1 | ¿La cosa que categorizo necesita **atributos propios** (descripción, imagen, marca, manager...)? | Sí | Custom Object |
| 2 | ¿La lista de valores **crece con el tiempo y la mantienen usuarios de negocio** (no admins)? | Sí | Custom Object |
| 3 | ¿Hay **otras entidades que necesitan relacionarse con esos valores**? | Sí | Custom Object |
| 4 | ¿Los valores son **finitos, estables, y pocos** (<50-100)? | Sí | Picklist |
| 5 | ¿Solo necesito el **nombre** del valor, nada más? | Sí | Picklist |

**Regla práctica**: si 3 o más preguntas inclinan al mismo lado, esa es la respuesta. Si está parejo, gana picklist por simplicidad.

**Ejemplo donde picklist gana**: campo "Estado del pedido" — valores fijos (Borrador / Pendiente / Aprobado / Enviado / Entregado), pocos, estables, sin atributos propios, los pone el admin.

**Ejemplo donde Custom Object gana**: campo "Categoría del producto" — valores con atributos propios (ícono, orden, descripción), crecen con el catálogo, otras entidades se relacionan con ellos.
