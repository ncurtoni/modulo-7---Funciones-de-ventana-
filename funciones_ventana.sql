-- =====================================================================
-- Ejercicio: Funciones de ventana (Unidad 1 - Data Science II)
-- Compatible con DuckDB y SQLite (3.25 o superior)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Preparación: tabla de pedidos con datos de prueba
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS pedidos;

CREATE TABLE pedidos (
    pedido_id  INTEGER PRIMARY KEY,
    cliente_id TEXT,
    fecha      DATE,
    importe    DECIMAL(10, 2),
    categoria  TEXT
);

INSERT INTO pedidos (pedido_id, cliente_id, fecha, importe, categoria) VALUES
    (1,  'A', '2026-01-05',  500.00, 'Electronica'),
    (2,  'B', '2026-01-06',  120.00, 'Hogar'),
    (3,  'A', '2026-01-10',   80.00, 'Libros'),
    (4,  'C', '2026-01-10', 1500.00, 'Electronica'),
    (5,  'B', '2026-01-15',  300.00, 'Hogar'),
    (6,  'C', '2026-01-18',   45.00, 'Libros'),
    (7,  'A', '2026-01-22', 2000.00, 'Electronica'),
    (8,  'D', '2026-01-25',  250.00, 'Hogar'),
    (9,  'B', '2026-01-28',   60.00, 'Libros'),
    (10, 'D', '2026-02-02', 1000.00, 'Electronica');


-- ---------------------------------------------------------------------
-- 1. Métricas por cliente
-- Cada pedido conserva su fila y suma el promedio histórico de su cliente.
-- ---------------------------------------------------------------------
SELECT
    pedido_id,
    cliente_id,
    fecha,
    importe,
    categoria,
    -- AVG sobre una ventana que solo contiene los pedidos del mismo cliente.
    -- PARTITION BY reinicia el cálculo para cada cliente_id.
    ROUND(AVG(importe) OVER (PARTITION BY cliente_id), 2) AS promedio_cliente,
    -- Diferencia entre el pedido y el promedio del cliente:
    -- positivo = gastó más de lo habitual, negativo = gastó menos.
    ROUND(importe - AVG(importe) OVER (PARTITION BY cliente_id), 2) AS desvio_vs_promedio
FROM pedidos
ORDER BY cliente_id, fecha;


-- ---------------------------------------------------------------------
-- 2. Ventas acumuladas de la empresa
-- ---------------------------------------------------------------------
SELECT
    fecha,
    pedido_id,
    importe,
    -- SUM con ORDER BY dentro de OVER: suma desde la primera fila hasta
    -- la actual. Se agrega pedido_id al orden para desempatar pedidos
    -- del mismo día y que el acumulado avance fila por fila.
    -- ROWS BETWEEN deja explícito el marco de la ventana.
    SUM(importe) OVER (
        ORDER BY fecha, pedido_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS ventas_acumuladas
FROM pedidos
ORDER BY fecha, pedido_id;


-- ---------------------------------------------------------------------
-- 3. Contribución de cada pedido al total de su categoría
-- ---------------------------------------------------------------------
SELECT
    pedido_id,
    categoria,
    importe,
    -- Total de la categoría repetido en cada fila de esa categoría.
    SUM(importe) OVER (PARTITION BY categoria) AS total_categoria,
    -- Porcentaje del pedido sobre su categoría.
    -- Se multiplica por 100.0 para forzar división decimal (en SQLite
    -- la división entre enteros trunca el resultado).
    ROUND(100.0 * importe / SUM(importe) OVER (PARTITION BY categoria), 2) AS pct_categoria
FROM pedidos
ORDER BY categoria, pct_categoria DESC;
