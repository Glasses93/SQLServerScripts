EXEC sys.sp_executesql
N';WITH x AS (
	SELECT
		srv = @@SERVERNAME, db = DB_NAME(), sch = s.[name], tbl = t.[name], obj_id = t.[object_id],
		idx = i.[name], idx_type = LOWER(i.[type_desc]), idx_id = i.[index_id],
		idx_keys       =
				CASE WHEN ic.[key_ordinal] = 1 THEN CONVERT(nvarchar(max), QUOTENAME(c.[name]))
			+	CASE WHEN i.[type_desc] IN (N''CLUSTERED'', N''NONCLUSTERED'') THEN CASE ic.[is_descending_key] WHEN 1 THEN N'' DESC'' ELSE N'' ASC'' END ELSE N'''' END ELSE N'''' END, 
		[incld_col(s)] = CASE ic.[is_included_column] WHEN 1 THEN CONVERT(nvarchar(max), QUOTENAME(c.[name])) ELSE N'''' END,
		idx_col_id     = ic.[index_column_id],
		filter_def     = COALESCE(i.[filter_definition], N''no filter applied''), i.[is_primary_key], i.[is_unique], i.[ignore_dup_key], i.[fill_factor], i.[is_disabled],
		col_no = 1
	FROM sys.schemas s
	INNER JOIN sys.tables t
		ON s.[schema_id] = t.[schema_id]
	INNER JOIN sys.indexes i
		ON t.[object_id] = i.[object_id]
	INNER JOIN sys.index_columns ic
		ON  i.[object_id] = ic.[object_id]
		AND i.[index_id]  = ic.[index_id]
	INNER JOIN sys.columns c
		ON  ic.[object_id] = c.[object_id]
		AND ic.column_id   = c.[column_id]
	WHERE t.[name] = @tbl
		AND 1 IN (ic.[key_ordinal], ic.[index_column_id])
	UNION ALL
	SELECT
		srv = x.srv, db = x.db, x.sch, x.tbl, x.obj_id, x.idx, x.idx_type, x.idx_id,
		idx_keys =
				CASE WHEN ic.[key_ordinal] = x.col_no + 1 THEN x.idx_keys + N'', '' + QUOTENAME(c.[name])
			+	CASE WHEN i.[type_desc] IN (N''CLUSTERED'', N''NONCLUSTERED'') THEN CASE ic.[is_descending_key] WHEN 1 THEN N'' DESC'' ELSE N'' ASC'' END ELSE N'''' END ELSE x.idx_keys END,
		[incld_col(s)] =
			CASE  
				WHEN ic.[is_included_column] = 1 AND x.[incld_col(s)] != N'''' THEN x.[incld_col(s)] + N'', '' + QUOTENAME(c.[name])
				WHEN ic.[is_included_column] = 1 AND x.[incld_col(s)]  = N'''' THEN QUOTENAME(c.[name])
				ELSE N''''
			END,
		idx_col_id = ic.[index_column_id],
		x.filter_def,
		x.[is_primary_key], x.[is_unique], x.[ignore_dup_key], x.[fill_factor], x.[is_disabled],
		col_no = x.col_no + 1
	FROM sys.schemas s
	INNER JOIN sys.tables t
		ON s.[schema_id] = t.[schema_id]
	INNER JOIN sys.indexes i
		ON t.[object_id] = i.[object_id]
	INNER JOIN sys.index_columns ic
		ON  i.[object_id] = ic.[object_id]
		AND i.[index_id]  = ic.[index_id]
	INNER JOIN sys.columns c
		ON  ic.[object_id] = c.[object_id]
		AND ic.[column_id] = c.[column_id]
	INNER JOIN x
		ON  i.[object_id] = x.[obj_id]
		AND i.[index_id]  = x.idx_id
		AND x.col_no + 1 IN (ic.[key_ordinal], ic.[index_column_id])
),
y AS (
	SELECT
		*, rn = ROW_NUMBER() OVER (PARTITION BY sch, idx_id ORDER BY col_no DESC),
		[compression] =
			CASE
				WHEN EXISTS (
					SELECT 1
					FROM sys.partitions p
					WHERE x.obj_id = p.[object_id]
						AND x.idx_id = p.[index_id]
						AND p.[data_compression_desc] = N''PAGE''
				)
					THEN ''page''
				WHEN EXISTS (
					SELECT 1
					FROM sys.partitions p
					WHERE x.obj_id = p.[object_id]
						AND x.idx_id = p.[index_id]
						AND p.[data_compression_desc] = N''ROW''
				)
					THEN ''row''
				WHEN EXISTS (
					SELECT 1
					FROM sys.partitions p
					WHERE x.obj_id = p.[object_id]
						AND x.idx_id = p.[index_id]
						AND p.[data_compression_desc] = N''NONE''
				)
					THEN ''none''
			END
	FROM x
)
SELECT srv, db, sch, tbl, idx, idx_type, idx_keys, [incld_col(s)], filter_def, [is_primary_key], [is_unique], [ignore_dup_key], [fill_factor], [is_disabled], [compression]
FROM y
WHERE rn = 1
ORDER BY sch, idx_id
;'
,N'@tbl sysname'
,Dates
;
