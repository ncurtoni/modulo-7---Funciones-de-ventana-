# Funciones de ventana: análisis de ventas

Ejercicio de la Unidad 1 de Data Science II (Coderhouse). El script `funciones_ventana.sql` crea una tabla `pedidos` con datos de prueba y resuelve tres consultas usando funciones de ventana, sin `GROUP BY`: cada resultado conserva las 10 filas de la tabla original.

## Cómo ejecutarlo

Con DuckDB:

```bash
duckdb < funciones_ventana.sql
```

Con SQLite (3.25 o superior):

```bash
sqlite3 -header -column < funciones_ventana.sql
```

## Qué resuelve cada consulta

1. **Métricas por cliente:** agrega a cada pedido el promedio histórico de gasto de su cliente y el desvío del pedido respecto de ese promedio.
2. **Ventas acumuladas:** calcula el total acumulado de ventas de la empresa en orden cronológico.
3. **Contexto por categoría:** calcula qué porcentaje del total de su categoría representa cada pedido (por ejemplo, el pedido 1 de Electrónica aporta 500 sobre 5000, es decir, el 10%).

## Por qué usé PARTITION BY en el punto 1

La pregunta es si un pedido está dentro del rango normal *de ese cliente*, no del promedio general de la empresa. Si usara `AVG(importe) OVER ()`, cada fila mostraría el promedio de toda la tabla (585,50), que no dice nada sobre el comportamiento individual.

`PARTITION BY cliente_id` hace que la ventana de cada fila contenga solo los pedidos del mismo cliente. Así, el cliente A tiene promedio 860 y su pedido de 2000 aparece claramente por encima de lo habitual (+1140), mientras que el de 80 queda muy por debajo (-780).

A diferencia de `GROUP BY cliente_id`, que devolvería una fila por cliente, la partición mantiene cada pedido con su detalle y le pone el promedio al lado. Ese es justamente el tipo de variable de contexto útil para Feature Engineering.

## Qué cambia si quito el ORDER BY en el punto 2

Con `ORDER BY` dentro de `OVER`, la ventana de cada fila va desde la primera fila hasta la actual, y la suma crece paso a paso: 500, 620, 700, 2200, y así hasta 5855.

Sin `ORDER BY`, es decir `SUM(importe) OVER ()`, la ventana pasa a ser toda la tabla. Todas las filas mostrarían el mismo valor, 5855, que es el total general. Se pierde por completo la idea de evolución en el tiempo.

### Un detalle sobre los empates

Los pedidos 3 y 4 tienen la misma fecha (2026-01-10). Si ordeno solo por `fecha` sin especificar el marco, el comportamiento por defecto (`RANGE`) trata a las filas empatadas como una sola posición, y ambas mostrarían 2200. Para que el acumulado avance fila por fila, agregué `pedido_id` como criterio de desempate y dejé explícito el marco con `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`.

## Detalle técnico del punto 3

El porcentaje se calcula como `100.0 * importe / SUM(importe) OVER (PARTITION BY categoria)`. El `100.0` fuerza división decimal: en SQLite, dividir dos enteros trunca el resultado y la mayoría de los porcentajes daría 0.
