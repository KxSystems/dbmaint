# DBMaint Module

KDB-X databases require ongoing maintenance as datasets evolve and schemas change. This module provides utility functions for kdb+ database tables, designed for use with [flat](https://code.kx.com/kdb-x/how_to/interact_with_databases/object.html), [splayed](https://code.kx.com/kdb-x/how_to/interact_with_databases/splayed-tables.html), [partitioned](https://code.kx.com/kdb-x/how_to/interact_with_databases/partition.html) and [segmented](https://code.kx.com/kdb-x/how_to/interact_with_databases/segment.html) tables. Think of these as on-disk equivalents of built-in q table functions: for example, `xcol` applies to in-memory tables, while `dbmaint.renameCol` applies to persisted tables.

The module provides three categories of utility:

1. **Health check functions**: Identify synchronization issues between partitions or between column files and column order (`.d`) files.
1. **Table-level functions**: Handle structural changes like adding, deleting, renaming tables or reordering columns of a table.
1. **Column-level functions**: Manage individual column names, attributes, and data transformations.

!!! warning
    Before using these functions on a production database, it is strongly recommended to test them on a sample database. You can create one using the [buildPersistedDB](https://github.com/KxSystems/datagen/blob/main/docs/references/capmkts.md#quickstart) function from the [KX Datagen](https://code.kx.com/kdb-x/modules/datagen/overview.html) module.

After modifying an existing database, reload it with `\l .` to apply changes to the active session.

## Loading the Module

Ensure the module is [installed](./install.md) and available on `QPATH`.

```q
dbmaint:use`kx.dbmaint
```

## Health Check Functions

Use the health check functions on partitioned tables.

- `checkTabExistence`: Checks if a table exists in all partitions of a database.
- `checkColFiles`: Checks table directories if column order files (`.d`) match column file list.
- `checkDotDEquality`: Checks all table partitions if column order files (`.d`) are the same.

All health check functions accept two parameters:

- path to the database root (string, symbol or file symbol)
- table name.

Example usages:

```q
dbmaint.checkTabExistence["db"; `quote]
```

```q
dbmaint.checkDotDEquality[`db; `trade]
```

## Table Functions

These functions operate at table level.

### `addTab`

Adds a new table to a database.

```q
dbmaint.addTab[`db;tname;schema;tabletype]
```

#### Parameters

| Parameter | Type                        | Description                                      |
|-----------|----------------------------|------------------------------------------------|
| `db`      | `string`, `symbol` or `fileSymbol` | Path to the database root.                      |
| `tname`   | `symbol`                   | Table name.                                     |
| `schema`  | `table`                    | Schema of the new table.                        |
| `tabletype` | `flat`, `splayed`, `partitioned` | Optional: type of the table (Default: `flat`)|
| `opt`  | `dict`                   | Optional: extra parameters. Possible keys<br> - domain (symbol): sym file domain name (default: ``` `sym```).<br> - compparam (triple or dictionary of triples): Compression parameter passed to `set` (default: `0 0 0i`) |

#### Example

Add the `quote` table to the database:

```q
dbmaint.addTab["db"; `quote; ([] sym:`$(); ap:"f"$(); bp:"f"$()); `partitioned]
```

Add `master` as a flat table to the database using compression gzip

```q
dbmaint.addTab[`:db;`master; ([] sym:`$(); description:(); cusip:`$()); `flat; ([compparam: 17 2 6])]
```

### `delTab`

Deletes a table from a database.

```q
dbmaint.delTab[`db;tname]
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

### `renameTab`

Renames a table.

```q
dbmaint.renameTab[`db;old;new]
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

### `copyTab`

Copies a table.

```q
dbmaint.copyTab[`db;src;dst]
```

#### Parameters

| Parameter | Type                        | Description                                      |
|-----------|----------------------------|------------------------------------------------|
| `db`      | `string`, `symbol` or `fileSymbol` | Path to the database root.                      |
| `src`     | `symbol`                   | Source table name.                             |
| `dst`     | `symbol`                   | Destination table name.                                 |

#### Example

Copy the `trade` table to `tradeBackup`:

```q
dbmaint.copyTab[`db;`trade;`tradeBackup]
```

### `reorderCols`

Reorders the columns across all partitions of a table.

```q
dbmaint.reorderCols[`db;tname;order]
```

#### Parameters

| Parameter | Type                        | Description                                      |
|-----------|----------------------------|------------------------------------------------|
| `db`      | `string`, `symbol` or `fileSymbol` | Path to the database root.                      |
| `tname`   | `symbol`                   | Table name.                                     |
| `order`   | `symbol`, `symbol[]`        | New column order (some or all columns).         |

#### Example

Reorder the columns of the `trade` table so that `sym`, `time`, and `price` appear first:

```q
dbmaint.reorderCols[`db;`trade;`sym`time`price]
```

## Column Functions

These functions operate at individual column level.

### `addCol`

Adds a column to a database table.

```q
dbmaint.addCol[`db;tname;cname;default]
```

or for new symbol columns

```q
dbmaint.addCol["db";tname;cname;default;domain]
```

#### Parameters

| Parameter | Type                        | Description                                      |
|-----------|----------------------------|------------------------------------------------|
| `db`      | `string`, `symbol` or `fileSymbol` | Path to the database root.                      |
| `tname`   | `symbol`                   | Table name.                                     |
| `cname`   | `symbol`                   | Column name.                                    |
| `default` | `any`                      | Default value for the column.                   |
| `opt`  | `dict`                   | Optional: extra parameters. Possible keys<br> - domain (symbol): sym file domain name (default: ``` `sym```).<br> - compparam (triple): Compression parameter passed to `set` (default: `0 0 0i`) |

#### Examples

Add a new column (`newCol`) to the `trade` table with a default value of 10:

```q
dbmaint.addCol[`:db;`trade;`newCol;10]
```

Add a new column (`newSymCol`) to the `trade` table, within all partitions under `db`, with a default value of `` `abc``, enumerated against `mySym`:

```q
dbmaint.addCol[`db;`trade;`newSymCol;`abc;([domain: `mySym])]
```

Add a new column (`newCol`) to the `quote` table with a default value of 3.14 using gzip compression

```q
dbmaint.addCol[`:db;`quote;`newCol;3.14;([compparam: 17 2 6])]
```

You can also add nested columns, such as strings:

```q
dbmaint.addCol[`:db;`trade;`message;"no message"]
```

### `delCol`

Deletes a column from a database table.

```q
dbmaint.delCol[`db;tname;cname]
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

### `renameCol`

Renames a column across all partitions of a table.

```q
dbmaint.renameCol[`db;tname;old;new]
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

### `fnCol`

Applies a function to a column across all partitions of a table.

```q
dbmaint.fnCol[`db;tname;cname;fn]
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
dbmaint.fnCol["db";`trade;`price;2*]
```

Negate the trade prices for yesterday

```q
dbmaint.fnCol[`db;`trade;`price;neg;.z.D-1]
```

Make the characters in the `alpha` column of the `trade` table uppercase:

```q
dbmaint.fnCol[`:db;`trade;`alpha;upper]
```

### `castCol`

Casts a column to a specified type.

```q
dbmaint.castCol[`db;tname;cname;typ]
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
dbmaint.setAttr[`:db;tname;cname;attrb]
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
dbmaint.rmAttr["db";tname;cname]
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
dbmaint.copyCol[`db;tname;srcCol;dstCol]
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

### `addMissingCols`

Adds missing columns across all partitions of a table.

```q
dbmaint.addMissingCols["db";tname;goodTdir]
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
dbmaint.addMissingCols[`:db;`trade;"db/2025.12.17/trade"]
```

### `listCols`

Lists all column names of the specified table. `listCols` only considers the last partition for partitioned tables.

```q
dbmaint.listCols[`db;tname]
```

#### Parameters

| Parameter | Type                        | Description                                      |
|-----------|----------------------------|------------------------------------------------|
| `db`      | `string`, `symbol` or `fileSymbol` | Path to the database root.                      |
| `tname`   | `symbol`                   | Table name.                                     |

#### Returns

(`symbol[]`) Column names.

#### Example

List the columns of the `trade` table:

```q
q)dbmaint.listCols[`db;`trade]
`time`sym`size`price`company`moves
```
