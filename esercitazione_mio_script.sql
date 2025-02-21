-- 1) Creazione e uso del database
CREATE DATABASE IF NOT EXISTS toysgroup_mio;
USE toysgroup_mio;

-- 2) Creazione tabella Category (una gerarchia: una categoria può avere molti prodotti)
CREATE TABLE Category (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL
);

-- 3) Creazione tabella Product (relazione con Category)
CREATE TABLE Product (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category_id INT NOT NULL,
    FOREIGN KEY (category_id) REFERENCES Category(category_id)
);

-- 4) Creazione tabella Region (macro aree geografiche)
CREATE TABLE Region (
    region_id INT AUTO_INCREMENT PRIMARY KEY,
    region_name VARCHAR(50) NOT NULL
);

-- 5) Creazione tabella State (sottocategorie geografiche incluse in Region)
CREATE TABLE State (
    state_id INT AUTO_INCREMENT PRIMARY KEY,
    state_name VARCHAR(50) NOT NULL,
    region_id INT NOT NULL,
    FOREIGN KEY (region_id) REFERENCES Region(region_id)
);

-- 6) Creazione tabella Sales (transazioni di vendita)
--    - Relazione con Product: 1..* (tante vendite per 1 prodotto)
--    - Relazione con Region:  1..* (tante vendite per 1 regione)
--      (da scenario: "Ciascuna transazione è riferita ad una sola regione")
CREATE TABLE Sales (
    sales_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    region_id INT NOT NULL,
    sale_date DATE NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    FOREIGN KEY (product_id) REFERENCES Product(product_id),
    FOREIGN KEY (region_id) REFERENCES Region(region_id)
);

-- 7) Inserimento dati di esempio

-- Categorie
INSERT INTO Category (category_name)
VALUES
('Bikes'),
('Clothing');

-- Prodotti
INSERT INTO Product (product_name, category_id)
VALUES
('Bikes-100', 1),
('Bikes-200', 1),
('Bike Glove M', 2),
('Bike Glove L', 2);

-- Regioni
INSERT INTO Region (region_name)
VALUES
('WestEurope'),
('SouthEurope');

-- Stati
INSERT INTO State (state_name, region_id)
VALUES
('France', 1),
('Germany', 1),
('Italy', 2),
('Greece', 2);

-- Transazioni di vendita
INSERT INTO Sales (product_id, region_id, sale_date, quantity)
VALUES
(1, 1, '2024-01-10', 10),  -- Bikes-100, WestEurope
(2, 1, '2024-01-12', 5),   -- Bikes-200, WestEurope
(3, 2, '2024-02-05', 12),  -- Bike Glove M, SouthEurope
(4, 2, '2024-02-06', 20);  -- Bike Glove L, SouthEurope

-- Verifica dei dati inseriti
SELECT * FROM Category;
SELECT * FROM Product;
SELECT * FROM Region;
SELECT * FROM State;
SELECT * FROM Sales; 


-- punto1 task4 verifica delle univocità delle Pk
-- 1.1) Category
SELECT 
    CASE WHEN COUNT(DISTINCT category_id) = COUNT(*) THEN 'OK' ELSE 'DUPLICATI' END AS PK_Categoria
FROM Category;

-- 1.2) Product
SELECT 
    CASE WHEN COUNT(DISTINCT product_id) = COUNT(*) THEN 'OK' ELSE 'DUPLICATI' END AS PK_Prodotto
FROM Product;

-- 1.3) Region
SELECT 
    CASE WHEN COUNT(DISTINCT region_id) = COUNT(*) THEN 'OK' ELSE 'DUPLICATI' END AS PK_Regione
FROM Region;

-- 1.4) State
SELECT 
    CASE WHEN COUNT(DISTINCT state_id) = COUNT(*) THEN 'OK' ELSE 'DUPLICATI' END AS PK_Stato
FROM State;

-- 1.5) Sales
SELECT 
    CASE WHEN COUNT(DISTINCT sales_id) = COUNT(*) THEN 'OK' ELSE 'DUPLICATI' END AS PK_Vendite
FROM Sales;

-- punto 2 task4

SELECT 
    s.sales_id AS codice_documento,
    s.sale_date AS data_di_vendita,
    p.product_name AS nome_prodotto,
    c.category_name AS categoria_prodotto,
    st.state_name AS nome_stato,
    r.region_name AS nome_regione,
    CASE 
        WHEN DATEDIFF(CURDATE(), s.sale_date) > 180 THEN TRUE 
        ELSE FALSE 
    END AS oltre_180_giorni
FROM Sales s
JOIN Product p ON s.product_id = p.product_id
JOIN Category c ON p.category_id = c.category_id
JOIN Region r ON s.region_id = r.region_id
JOIN State st ON st.region_id = r.region_id;  -- Potrebbe duplicare righe se una regione ha più stati,
                                                -- ma rispettiamo la richiesta di mostrare 'nome_stato'. 

-- 3) Prodotti con quantità venduta maggiore della media (riferita all'ultimo anno censito)
SELECT 
    vendite_per_prodotto.product_id,
    vendite_per_prodotto.total_venduto
FROM (
    -- Somma delle vendite per ogni prodotto nell'ultimo anno censito
    SELECT 
        s.product_id,
        SUM(s.quantity) AS total_venduto
    FROM Sales s
    WHERE YEAR(s.sale_date) = (
        SELECT MAX(YEAR(s2.sale_date)) 
        FROM Sales s2
    )
    GROUP BY s.product_id
) AS vendite_per_prodotto
WHERE vendite_per_prodotto.total_venduto >
(
    -- Media delle vendite di tutti i prodotti nell'ultimo anno censito
    SELECT AVG(sub_totale.total_q)
    FROM (
        SELECT 
            SUM(s.quantity) AS total_q
        FROM Sales s
        WHERE YEAR(s.sale_date) = (
            SELECT MAX(YEAR(s2.sale_date)) 
            FROM Sales s2
        )
        GROUP BY s.product_id
    ) AS sub_totale
); 

SELECT 
    p.product_id,
    p.product_name,
    YEAR(s.sale_date) AS anno,
    SUM(s.quantity) AS fatturato_per_anno
FROM Product p
JOIN Sales s ON p.product_id = s.product_id
GROUP BY 
    p.product_id,
    p.product_name,
    YEAR(s.sale_date); 

SELECT 
    st.state_name,
    YEAR(s.sale_date) AS anno,
    SUM(s.quantity) AS fatturato_totale
FROM Sales s
JOIN Region r ON s.region_id = r.region_id
JOIN State st ON st.region_id = r.region_id
GROUP BY 
    st.state_name, 
    YEAR(s.sale_date)
ORDER BY 
    YEAR(s.sale_date),
    fatturato_totale DESC; 

SELECT 
    c.category_name,
    SUM(s.quantity) AS totale_venduto
FROM Sales s
JOIN Product p ON s.product_id = p.product_id
JOIN Category c ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY totale_venduto DESC
LIMIT 1; 

-- 7.1) Con la condizione NOT EXISTS
SELECT 
    p.product_id,
    p.product_name
FROM Product p
WHERE NOT EXISTS (
    SELECT 1 
    FROM Sales s 
    WHERE s.product_id = p.product_id
);

-- 7.2) Con LEFT JOIN e condizione su campo NULL nella tabella Sales
SELECT 
    p.product_id,
    p.product_name
FROM Product p
LEFT JOIN Sales s ON p.product_id = s.product_id
WHERE s.product_id IS NULL; 

CREATE OR REPLACE VIEW vw_product_info AS
SELECT 
    p.product_id,
    p.product_name,
    c.category_name
FROM Product p
JOIN Category c ON p.category_id = c.category_id; 

CREATE OR REPLACE VIEW vw_geography AS
SELECT 
    st.state_id,
    st.state_name,
    r.region_name
FROM State st
JOIN Region r ON st.region_id = r.region_id; 