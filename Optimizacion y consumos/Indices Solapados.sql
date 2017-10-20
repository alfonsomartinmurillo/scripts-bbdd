
	-- CONSULTA PARA IDENTIFICAR ÍNDICES SOLAPADOS
WITH IndexColumns AS (
    SELECT 
	    '[' + s.Name + '].[' + T.Name + ']' AS TableName,
        ix.name AS IndexName,  
        c.name AS ColumnName, 
        ix.index_id,
        ixc.index_column_id,
        COUNT(*) OVER(PARTITION BY t.OBJECT_ID, ix.index_id) AS ColumnCount
    FROM sys.schemas AS s
    INNER JOIN sys.tables AS t ON 
	    t.schema_id = s.schema_id
    INNER JOIN sys.indexes AS ix ON 
	    ix.OBJECT_ID = t.OBJECT_ID
    INNER JOIN sys.index_columns AS ixc ON  
	    ixc.OBJECT_ID = ix.OBJECT_ID AND 
		ixc.index_id = ix.index_id
    INNER JOIN sys.columns AS c ON  
	    c.OBJECT_ID = ixc.OBJECT_ID AND 
		c.column_id = ixc.column_id
    WHERE 
        ixc.is_included_column = 0 AND
        LEFT(ix.name, 2) NOT IN ('PK', 'UQ', 'FK')
	--ORDER BY TABLENAME, INDEXNAME, COLUMNNAME, INDEX_ID,INDEX_COLUMN_ID, COLUMNCOUNT
)
SELECT
	*
FROM
	INDEXCOLUMNS AS IX1
	INNER JOIN
	INDEXCOLUMNS AS IX2 ON
	ix1.TableName = ix2.TableName AND
	ix1.IndexName <> ix2.IndexName AND 
	ix1.index_column_id = ix2.index_column_id AND  
	ix1.ColumnName = ix2.ColumnName  AND 
	ix1.ColumnCount <= ix2.ColumnCount

	--select * from sys.index_columns