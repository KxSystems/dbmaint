# DBMaint kdb-x installation

[`dbmaint.q`](../dbmaint.q) is written as a module, under kdb-x's module framework. Though modules can be loaded from anywhere if added to your `$QPATH`, we recommend installing to the `$HOME/.kx/mod/kx` folder. This is to avoid name clashes with other user defined modules, as well as providing a location for other KX modules to cross reference each other (e.g. the logging module references `printf`)

```bash
export QPATH="$QPATH:$HOME/.kx/mod"
mkdir -p ~/.kx/mod/kx/
cp dbmaint.q ~/.kx/mod/kx/
```

Now from anywhere you can import the DBMaint module.

```q
q)dbmaint:use`kx.dbmaint;
q)dbmaint.addCol[`:partDB;`sym;`trade;`side;`b]
```

Add the export to your bashrc or equivalent to persist across sessions.
