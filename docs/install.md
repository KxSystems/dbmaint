# DBMaint kdb-x installation

## Install module with qmamba

qmamba is a package manager for kdb-x. It is currently available in a private preview capacity. You are welcome to try it and provide feedback.
Follow the install instructions for [qmamba](https://github.com/KxSystems/qmamba/blob/main/README.md#installation).

```q
qmamba:use`kx.qmamba
qmamba.create "myenv"
qmamba.activate "myenv"
qmamba.install `SPECS`CHANNEL!(enlist "q-kx-dbmaint";enlist"kx")
.dbmaint:use`kx.dbmaint
```

## Installation

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
