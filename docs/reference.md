# DBMaint Module

This module provides utility functions for maintaining partitioned kdb+ database tables. It is not designed for use with splayed tables that are not partitioned, single-file tables, or in-memory tables.

Before using these functions on a production database, it is strongly recommended to test them on a sample database. You can create a sample database using the [buildPersistedDB](https://github.com/KxSystems/datagen/blob/main/docs/references/capmkts.md#quickstart) function from the [KX Datagen](https://code.kx.com/kdb-x/modules/datagen/overview.html) module.

If you make changes to an existing database, you must reload it using (`\l .`) to apply the modifications.

## Loading the Module

Ensure the module is [installed](./install.md) and available on `QPATH`.

```q
dbmaint:use`kx.dbmaint
```

## Functions

### `addCol`

Adds a column to a database table.

```q
dbmaint.addCol[db;tname;cname;default]
```

or for new symbol columns

```q
dbmaint.addCol[db;tname;cname;default;domain]
```

#### Parameters

| Parameter | Type                        | Description                                      |
|-----------|----------------------------|------------------------------------------------|
| `db`      | `string`, `symbol` or `fileSymbol` | Path to the database root.                      |
| `tname`   | `symbol`                   | Table name.                                     |
| `cname`   | `symbol`                   | Column name.                                    |
| `default` | `any`                      | Default value for the column.                   |
| `domain`  | `symbol`                   | Optional: Sym file (domain) name (only used if the column is of symbol type). |

#### Examples

Add a new column (`newCol`) to the `trade` table with a default value of 10:

```q
dbmaint.addCol[`db;`trade;`newCol;10]
```

Add a new column (`newSymCol`) to the `trade` table, within all partitions under `db`, with a default value of `` `abc``, enumerated against `mySym`:

```q
dbmaint.addCol[`db;`trade;`newSymCol;`abc;`mySym]
```

### `addMissingCols`

Adds missing columns across all partitions of a table.

```q
dbmaint.addMissingCols[db;tname;goodTdir]
```

#### Parameters

| Parameter  | Type        | Description                                      |
|------------|-------------|------------------------------------------------|
| `db`       | `string`, `symbol` or `fileSymbol` | Path to the database root.                      |
| `tname`    | `symbol`     | Table name.                                     |
| `goodTdir` | `string`, `symbol` or `fileSymbol` | Path to a table directory that contains all required columns. |

#### Example

Add any missing columns to the `trade` table that exist in the `2025.12.17` partition but are missing from other partitions:

```q
dbmaint.addMissingCols[`db;`trade;"db/2025.12.17/trade"]
```

### `addTab`

Adds a new table to all partitions of a database.

```q
dbmaint.addTab[db;domain;tname;schema]
```

#### Parameters

| Parameter | Type                        | Description                                      |
|-----------|----------------------------|------------------------------------------------|
| `db`      | `string`, `symbol` or `fileSymbol` | Path to the database root.                      |
| `domain`  | `symbol`                   | Sym file (domain) name.                         |
| `tname`   | `symbol`                   | Table name.                                     |
| `schema`  | `table`                    | Schema of the new table.                        |

#### Example

Add the `quote` table to the database:

```q
dbmaint.addTab[`db;`quote;([] sym:`$(); ap:"f"$(); bp:"f"$())]
```

### `fnCol`

Applies a function to a column across all partitions of a table.

```q
dbmaint.fnCol[db;tname;cname;fn]
```

#### Parameters

| Parameter | Type                        | Description                                   |
|-----------|----------------------------|------------------------------------------------|
| `db`      | `string`, `symbol` or `fileSymbol` | Path to the database root.             |
| `tname`   | `symbol`                   | Table name.                                    |
| `cname`   | `symbol`                   | Column name.                                   |
| `fn`      | `function`                 | Unary function to apply to the column.         |
| `dates`   | `date\|date[]`             | Optional: date(s) to restrict to.              |

#### Examples

Multiply the `price` column in the `trade` table by 2:

```q
dbmaint.fnCol[`db;`trade;`price;2*]
```

Negate the trade prices for yesterday

```q
dbmaint.fnCol[`db;`trade;`price;neg;.z.D-1]
```

Make the characters in the `alpha` column of the `trade` table uppercase:

```q
dbmaint.fnCol[`db;`trade;`alpha;upper]
```

### `castCol`

Casts a column to a specified type.

```q
dbmaint.castCol[db;tname;cname;typ]
```

#### Parameters

| Parameter | Type            | Description                                     |
|-----------|-----------------|-------------------------------------------------|
| `db`      | `fileSymbol`    | Path to the database root.                      |
| `tname`   | `symbol`        | Table name.                                     |
| `cname`   | `symbol`        | Column name.                                    |
| `type`    | `short\|char\|symbol` | Type to cast the column to.               |
| `dates`   | `date\|date[]`        | Optional: date(s) to restrict to.         |

#### Example

Cast the `size` column in the `trade` table to a `float`:

```q
dbmaint.castCol[`db;`trade;`size;"f"]
```

### `setAttr`

Sets an attribute on a column.

```q
dbmaint.setAttr[db;tname;cname;attrb]
```

#### Parameters

| Parameter | Type                        | Description                                    |
|-----------|----------------------------|-------------------------------------------------|
| `db`      | `string`, `symbol` or `fileSymbol` | Path to the database root.              |
| `tname`   | `symbol`                   | Table name.                                     |
| `cname`   | `symbol`                   | Column name.                                    |
| `attrb`   | `symbol`                   | Attribute (`s`, `u`, `p`, `g`).                 |
| `dates`   | `date\|date[]`        | Optional: date(s) to restrict to.                    |

#### Example

Apply the parted attribute to the `sym` column in the `trade` table:

```q
dbmaint.setAttr[`db;`trade;`sym;`p]
```

### `rmAttr`

Removes an attribute from a column.

```q
dbmaint.rmAttr[db;tname;cname]
```

#### Parameters

| Parameter | Type                        | Description                                    |
|-----------|----------------------------|-------------------------------------------------|
| `db`      | `string`, `symbol` or `fileSymbol` | Path to the database root.              |
| `tname`   | `symbol`                   | Table name.                                     |
| `cname`   | `symbol`                   | Column name.                                    |
| `dates`   | `date\|date[]`             | Optional: date(s) to restrict to.               |

#### Example

Remove the attribute from the `sym` column in the `trade` table:

```q
dbmaint.rmAttr[`db;`trade;`sym]
```

### `copyCol`

Copies a column across all partitions of a table.

```q
dbmaint.copyCol[db;tname;srcCol;dstCol]
```

#### Parameters

| Parameter | Type                        | Description                                      |
|-----------|----------------------------|------------------------------------------------|
| `db`      | `string`, `symbol` or `fileSymbol` | Path to the database root.                      |
| `tname`   | `symbol`                   | Table name.                                     |
| `srcCol`  | `symbol`                   | Name of the column to copy.                     |
| `dstCol`  | `symbol`                   | Name of the new column to create.               |

#### Example

Copy the `size` column to a new column called `sizeCopy` in the `trade` table:

```q
dbmaint.copyCol[`db;`trade;`size;`sizeCopy]
```

### `delCol`

Deletes a column from a database table.

```q
dbmaint.delCol[db;tname;cname]
```

#### Parameters

| Parameter | Type                        | Description                                      |
|-----------|----------------------------|------------------------------------------------|
| `db`      | `string`, `symbol` or `fileSymbol` | Path to the database root.                      |
| `tname`   | `symbol`                   | Table name.                                     |
| `cname`   | `symbol`                   | Column name.                                    |

#### Example

Delete the column `oldCol` from the `trade` table:

```q
dbmaint.delCol[`db;`trade;`oldCol]
```

### `delTab`

Deletes a table from a database.

```q
dbmaint.delTab[db;tname]
```

#### Parameters

| Parameter | Type                        | Description                                      |
|-----------|----------------------------|------------------------------------------------|
| `db`      | `string`, `symbol` or `fileSymbol` | Path to the database root.                      |
| `tname`   | `symbol`                   | Table name.                                     |

#### Example

Delete the `trade` table:

```q
dbmaint.delTab[`db;`trade]
```

### `hasCol`

Checks if a given column exists in the table.

```q
dbmaint.hasCol[db;tname;cname]
```

#### Parameters

| Parameter | Type                        | Description                                      |
|-----------|----------------------------|------------------------------------------------|
| `db`      | `string`, `symbol` or `fileSymbol` | Path to the database root.                      |
| `tname`   | `symbol`                   | Table name.                                     |
| `cname`   | `symbol`                   | Column name.                                    |

#### Returns

(`bool`) `1b` if the column exists in the table, `0b` otherwise.

#### Example

Check if the `trade` table has the `size` column:

```q
dbmaint.hasCol[`db;`trade;`size]
```

### `listCols`

Lists all column names of the specified table.

```q
dbmaint.listCols[db;tname]
```

#### Parameters

| Parameter | Type                        | Description                                      |
|-----------|----------------------------|------------------------------------------------|
| `db`      | `string`, `symbol` or `fileSymbol` | Path to the database root.                      |
| `tname`   | `symbol`                   | Table name.                                     |

#### Returns

(`symbols`) Column names.

#### Example

List the columns of the `trade` table:

```q
q)dbmaint.listCols[`db;`trade]
`time`sym`size`price`company`moves
```

### `renameCol`

Renames a column across all partitions of a table.

```q
dbmaint.renameCol[db;tname;old;new]
```

#### Parameters

| Parameter | Type                        | Description                                      |
|-----------|----------------------------|------------------------------------------------|
| `db`      | `string`, `symbol` or `fileSymbol` | Path to the database root.                      |
| `tname`   | `symbol`                   | Table name.                                     |
| `old`     | `symbol`                   | Current column name.                            |
| `new`     | `symbol`                   | New column name.                                |

#### Example

Rename the `size` column to `sizeRenamed` in the `trade` table:

```q
dbmaint.renameCol[`db;`trade;`size;`sizeRenamed]
```

### `renameTab`

Renames a table in all partitions.

```q
dbmaint.renameTab[db;old;new]
```

#### Parameters

| Parameter | Type                        | Description                                      |
|-----------|----------------------------|------------------------------------------------|
| `db`      | `string`, `symbol` or `fileSymbol` | Path to the database root.                      |
| `old`     | `symbol`                   | Current table name.                             |
| `new`     | `symbol`                   | New table name.                                 |

#### Example

Rename the `trade` table to `quote`:

```q
dbmaint.renameTab[`db;`trade;`quote]
```

### `reorderCols`

Reorders the columns across all partitions of a table.

```q
dbmaint.reorderCols[db;tname;order]
```

#### Parameters

| Parameter | Type                        | Description                                      |
|-----------|----------------------------|------------------------------------------------|
| `db`      | `string`, `symbol` or `fileSymbol` | Path to the database root.                      |
| `tname`   | `symbol`                   | Table name.                                     |
| `order`   | `symbols`                  | New column order (some or all columns).         |

#### Example

Reorder the columns of the `trade` table so that `sym`, `time`, and `price` appear first:

```q
dbmaint.reorderCols[`db;`trade;`sym`time`price]
```
