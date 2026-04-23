dbmaint: use `$"..dbmaint";
([getInMemoryTables; buildPersistedDB]): use `kx.datagen.capmkts

dbdir: hsym `$first .z.x

start: 2026.04.01;
end: 2026.04.03;

fail: {-2 x;'`failed}

initGenData:{[db; mastertype]
  rmrf db;
  buildPersistedDB[db; ([tbls: `trade`daily; start; end; mastertype])]
  }

isWindows:.z.o in `w32`w64;

// @brief Check if a given file/directory exists.
// @param path fileSymbol Path of a file/directory.
// @return boolean 1b if path exists, 0b otherwise.
exists:{[path] not ()~key path};

// @brief Recursively list all files and sub-directories within a given directory.
// @param dir fileSymbol Top level directory whose contents are to be listed.
// @return fileSymbols Relative list of paths to files and sub-directories.
rlist:{[dir]
    $[
        not exists dir; `$();
        count p:.Q.dd[dir;] each key dir; raze p,'.z.s each p;
        `$()
    ]
 };

// @brief Foreceful and recursive removal of a file/directory.
// @param dir fileSymbol Path to file/directory to remove.
rmrf:{[path] if[exists path; hdel each desc path,rlist path]}

// @brief Convert a file path to a correctly formatted string path based on the platform.
// @param path fileSymbol File path to format.
// @return String Converted file path.
toPlatformPath:{[path]
    path:string path;
    if[isWindows; path[where"/"=path]:"\\"];
    (":"=first path)_ path
 };

// @brief Create a directory.
// @param dir fileSymbol Directory to create.
mkdir:{[dir] system $[isWindows; "mkdir "; "mkdir -p "],toPlatformPath dir;};

// @brief Get the directory of the given path.
// @param x fileSymbol Path to get directory name of.
// @return fileSymbol Directory name.
dirname:first ` vs;

// @brief Copy a source file to a destination file.
// @param src fileSymbol File to copy.
// @param dst fileSymbol Location to copy to.
copy:{[src;dst]
    mkdir dirname dst; // Ensure parent directory already exists
    system $[isWindows; "copy /v /z "; "cp "]," " sv toPlatformPath each src,dst;
 };


// @brief Recursively copy a source directory to a destination directory.
// @param src fileSymbol File to copy.
// @param dst fileSymbol Location to copy to.
rcopy:{[src;dst]
    files:rlist src;
    copy'[files;] `$(string[dst],count[string src]_) each string files;
 };

// @brief Assert x is a truthy value.
// @param x any Q object.
assert.true:{
    if[not x; fail "ASSERT TRUE | Expected ",.Q.s1[x]," to be a truthy value"]
 };

// @brief Assert x is a falsey value.
// @param x any Q object.
assert.false:{
    if[x; fail "ASSERT FALSE | Expected ",.Q.s1[x]," to be a falsey value"]
 };

// @brief Assert that x equals y.
// @param x any Q object.
// @param y any Q object.
assert.eq:{
    if[not x=y; fail "ASSERT EQUAL | Expected ",.Q.s1[x]," = ",.Q.s1 y]
 };


// @brief Assert that x matches y.
// @param x any Q object.
// @param y any Q object.
assert.match:{
    if[not x~y; fail "ASSERT MATCH | Expected ",.Q.s1[x]," ~ ",.Q.s1 y]
 };

// @brief Assert that function application raises an error.
// @param f function Function to apply.
// @param args list Function arguments.
// @param err string Expected error.
assert.fail:{[f;args;err]
    if[(0h>type args) or args~(); args:enlist args];
    .[
        f;
        args;
        {if[not x like y; fail "ASSERT FAIL | Expected error ",.Q.s1[x],", but got ",.Q.s1 y]}[err;]
    ]
 };

testCheckTabExistence:{[]
    initGenData[dbdir; `flat];

    assert.true dbmaint.checkTabExistence[dbdir; `master];
    assert.true dbmaint.checkTabExistence[dbdir; `daily];
    assert.true dbmaint.checkTabExistence[dbdir; `trade];

    rmrf .Q.dd[dbdir; start,`trade];
    assert.fail[
        dbmaint.checkTabExistence;
        (dbdir; `trade);
        "kdb+ object not found at: ", 1_string .Q.dd[dbdir;start,`trade]];
 };

testCheckColFiles:{[]
    initGenData[dbdir; `flat];

    dbmaint.checkColFiles[dbdir; `master];
    dbmaint.checkColFiles[dbdir; `daily];
    dbmaint.checkColFiles[dbdir; `trade];

  };

testCheckColFilesNested:{[]
    initGenData[dbdir; `splayed];

    dbmaint.checkColFiles[dbdir; `master];

    copy[.Q.dd[dbdir;`master`cusip]; .Q.dd[dbdir;`master`cusip2]];
    assert.fail[dbmaint.checkColFiles; (dbdir; `master); "Unknown column file(s): cusip2"];
    rmrf .Q.dd[dbdir; `master`cusip2];

    copy[.Q.dd[dbdir;`2026.04.01`trade`size]; .Q.dd[dbdir;`2026.04.01`trade`size2]];
    assert.fail[dbmaint.checkColFiles; (dbdir; `trade); "Unknown column file(s): size2"];
    rmrf .Q.dd[dbdir; `trade`size2];

    rmrf .Q.dd[dbdir; `master`cusip];
    assert.fail[dbmaint.checkColFiles; (dbdir; `master); "Missing column file(s): cusip"];
  };

testCheckDotDEquality:{[]
    initGenData[dbdir; `splayed];

    .Q.dd[dbdir;`2026.04.02`trade`.d] set reverse get .Q.dd[dbdir;`2026.04.02`trade`.d];
    assert.fail[dbmaint.checkDotDEquality; (dbdir; `trade);
        ".d mismatch at: ", 1_string .Q.dd[dbdir;`2026.04.02`trade]];
  };

testListCols:{[]
    initGenData[dbdir; `flat];

    assert.fail[
        dbmaint.listCols;
        (dbdir; `nonExistingTab);
        "kdb+ object not found at: ", 1_string .Q.dd[dbdir;end,`nonExistingTab]
    ];

    / TODO: more checks here, currently just verifying it runs without error
    dbmaint.listCols[dbdir;`master];
    dbmaint.listCols[dbdir;`daily];
    dbmaint.listCols[dbdir;`trade];
 };

testAddColFlat:{[]
    initGenData[dbdir; `flat];

    master: get .Q.dd[dbdir;`master];
    dbmaint.addCol[dbdir;`master;`newCol;42];
    dbmaint.addCol[dbdir;`master;`newSymCol;`mysym];
    dbmaint.addCol[dbdir;`master;`newSymColMatch;`cusip];
    dbmaint.addCol[dbdir;`master;`newStringCol; "string"];
    assert.match[get .Q.dd[dbdir;`master]; (update newCol:42, newSymCol:`mysym, newSymColMatch:`cusip from master)
        cross ([] newStringCol: enlist "string")];
 };

testAddColSplay:{[]
    initGenData[dbdir; `flat];

    assert.fail[
        dbmaint.addCol;
        (dbdir;`daily;`open;0N);
        "kdb+ object open found at: ", 1_string .Q.dd[dbdir;`daily]
    ];

    dailyColNames: dbmaint.listCols[dbdir;`daily];
    dbmaint.addCol[dbdir;`daily;`newCol;42];
    dbmaint.addCol[dbdir;`daily;`newSymCol;`mysym];
    dbmaint.addCol[dbdir;`daily;`newSymColMatch;`cusip];
    dbmaint.addCol[dbdir;`daily;`newStringCol; "string"];
    assert.true all `newCol`newSymCol`newSymColMatch`newStringCol in key .Q.dd[dbdir;`daily];
    assert.true all `newCol`newSymCol`newSymColMatch`newStringCol in get .Q.dd[dbdir;`daily`.d];
    assert.true all 42=get .Q.dd[dbdir;`daily`newCol];
    assert.true all `mysym=get .Q.dd[dbdir;`daily`newSymCol];
    assert.true all `cusip=get .Q.dd[dbdir;`daily`newSymColMatch];
    assert.true all "string" ~/: get .Q.dd[dbdir;`daily`newStringCol];
    assert.match[([]); -21!.Q.dd[dbdir;`daily`newCol]];

    assert.match[dbmaint.listCols[dbdir;`daily]; dailyColNames,`newCol`newSymCol`newSymColMatch`newStringCol];
 };

testAddColSplayCompr:{[]
    initGenData[dbdir; `flat];

    dailyColNames: dbmaint.listCols[dbdir;`daily];
    dbmaint.addCol[dbdir;`daily;`newCol;0N; ([compparam: 17 2 6])];
    assert.true `newCol in key .Q.dd[dbdir;`daily];
    assert.true `newCol in get .Q.dd[dbdir;`daily`.d];
    assert.true all 0N=get .Q.dd[dbdir;`daily`newCol];
    assert.match[2 17 6i; -3 sublist value -21!.Q.dd[dbdir;`daily`newCol]];

    assert.match[dbmaint.listCols[dbdir;`daily]; dailyColNames,`newCol];
 };

testAddColPart:{[]
    initGenData[dbdir; `flat];

    // No affect since column already exists
    tradeColNames: dbmaint.listCols[dbdir;`trade];

    res: .[dbmaint.addCol; (dbdir;`trade;`size;0N); ::];
    if[not res like "kdb+ object size found at: *"];

    dbmaint.addCol[dbdir;`trade;`newCol;0N];
    {
        assert.true `newCol in key x;
        assert.true `newCol in get x,`.d;
        assert.true all 0N=get x,`newCol
    } each {.Q.dd[dbdir;x,`trade]} each start + til 1+ end - start;

    dbmaint.addCol[dbdir;`trade;`newSymCol;`symvalues;([domain:`sym])];
    {
        assert.true `newSymCol in key x;
        assert.true `newSymCol in get x,`.d;
        assert.true all `symvalues=get x,`newSymCol
    } each {.Q.dd[dbdir;x,`trade]} each start + til 1+ end - start;
    assert.match[dbmaint.listCols[dbdir;`trade]; tradeColNames,`newCol`newSymCol];
 };

testDelColFlat:{[]
    initGenData[dbdir; `flat];

    assert.fail[
        dbmaint.delCol;
        (dbdir;`master;`nonExistingCol);
        "Column nonExistingCol does not exist in master"
    ];

    colNames: cols get .Q.dd[dbdir;`master];
    dbmaint.delCol[dbdir;`master;`cusip];
    assert.match[cols get .Q.dd[dbdir;`master]; colNames except `cusip];
 };

testDelColSplay:{[]
    initGenData[dbdir; `splayed];

    assert.fail[
        dbmaint.delCol;
        (dbdir;`daily;`nonExistingCol);
        "kdb+ object nonExistingCol not found at: ", 1_string .Q.dd[dbdir;`daily]
    ];

    colNames:get .Q.dd[dbdir;`daily`.d];
    dbmaint.delCol[dbdir;`daily;`open];
    assert.match[asc (key .Q.dd[dbdir;`daily]) except `.d; asc colNames except `open];
    assert.match[get .Q.dd[dbdir;`daily`.d]; colNames except `open];

    // Delete nested - should delete associated # file
    colNames:get .Q.dd[dbdir;`master`.d];
    dbmaint.delCol[dbdir;`master;`description];
    assert.match[asc (key .Q.dd[dbdir;`master]) except `.d; asc colNames except `description, `$"description#"];
    assert.match[get .Q.dd[dbdir;`master`.d]; colNames except `description];
 };

testDelColPart:{[]
     initGenData[dbdir; `flat];

    res: .[dbmaint.delCol; (dbdir;`trade;`nonExistingCol); ::];
    if[not res like "kdb+ object nonExistingCol not found at: *";
        fail "ASSERT FAIL | Expected error message to contain 'kdb+ object nonExistingCol not found at: *', but got ", res];

    dbmaint.delCol[dbdir;`trade;`size];
    {
        assert.false `size in key .Q.dd[dbdir;x,`trade];
        assert.false `size in get .Q.dd[dbdir;x,`trade`.d];
    } each start + til 1+ end - start;
 };

testCopyColFlat:{[]
    initGenData[dbdir; `flat];

    assert.fail[
        dbmaint.copyCol;
        (dbdir;`master;`description;`description);
        "Source and destination column names must be different"
    ];

    assert.fail[
        dbmaint.copyCol;
        (dbdir;`master;`nonExistingCol;`nonExistingColCopy);
        "Column nonExistingCol does not exist in master"
    ];

    assert.fail[
        dbmaint.copyCol;
        (dbdir;`master;`cusip;`ex);
        "Column ex exists in master"
    ];

    colNames: cols get .Q.dd[dbdir;`master];
    dbmaint.copyCol[dbdir;`master;`cusip;`cusipCopy];
    assert.match[cols get .Q.dd[dbdir;`master]; colNames,`cusipCopy];
    assert.match[get[.Q.dd[dbdir;`master]]`cusip; get[.Q.dd[dbdir;`master]]`cusipCopy];
 };

testCopyColSplay:{[]
    initGenData[dbdir; `splayed];

    assert.fail[
        dbmaint.copyCol;
        (dbdir;`daily;`nonExistingCol;`nonExistingColCopy);
        "kdb+ object nonExistingCol not found at: ", 1_string .Q.dd[dbdir;`daily]
    ];

    assert.fail[
        dbmaint.copyCol;
        (dbdir;`daily;`open;`close);
        "Column close exists in ", 1_string .Q.dd[dbdir;`daily]
    ];

    colNames: get .Q.dd[dbdir;`daily`.d];
    dbmaint.copyCol[dbdir;`daily;`open;`openCopy];
    assert.match[get .Q.dd[dbdir;`daily`.d]; colNames,`openCopy];
    assert.match[get .Q.dd[dbdir;`daily`open]; get .Q.dd[dbdir;`daily`openCopy]];

    // Copy nested - should copy associated # file
    colNames: get .Q.dd[dbdir;`master`.d];
    dbmaint.copyCol[dbdir;`master;`description;`descriptionCopy];
    assert.match[get .Q.dd[dbdir;`master`.d]; colNames,`descriptionCopy];
    assert.true all (`description,`$"description#") in key .Q.dd[dbdir;`master];
    assert.match[get .Q.dd[dbdir;`master`description]; get .Q.dd[dbdir;`master`descriptionCopy]];
    assert.match[get .Q.dd[dbdir;`master,`$"description#"]; get .Q.dd[dbdir;`master,`$"descriptionCopy#"]];
 };

testCopyColPart:{[]
    initGenData[dbdir; `flat];

    res: .[dbmaint.copyCol; (dbdir;`trade;`nonExistingCol;`nonExistingColCopy); ::];
    if[not res like "kdb+ object nonExistingCol not found at: *";
        fail "ASSERT FAIL | Expected error message to contain 'kdb+ object nonExistingCol not found at: *', but got ", res];

    assert.fail[
        dbmaint.copyCol;
        (dbdir;`trade;`size;`price);
        "Column price exists in ", 1_string .Q.dd[dbdir;start, `trade]
    ];

    dbmaint.copyCol[dbdir;`trade;`size;`sizeCopy];
    {
        assert.true `sizeCopy in key .Q.dd[dbdir;x,`trade];
        assert.true `sizeCopy in get .Q.dd[dbdir;x,`trade`.d];
        assert.match[get .Q.dd[dbdir;(x;`trade;`sizeCopy)];get .Q.dd[dbdir;(x;`trade;`sizeCopy)]];
    } each start + til 1+ end - start;
 };

testRenameColFlat:{[]
    initGenData[dbdir; `flat];

    assert.fail[
        dbmaint.renameCol;
        (dbdir;`master;`description;`description);
        "New column name must be different from old column name"
    ];
    assert.fail[
        dbmaint.renameCol;
        (dbdir;`master;`nonExistingCol;`nonExistingColCopy);
        "Column nonExistingCol does not exist in master"
    ];

    assert.fail[
        dbmaint.renameCol;
        (dbdir;`master;`cusip;`ex);
        "Column ex exists in master"
    ];

    colNames: cols get .Q.dd[dbdir;`master];
    dbmaint.renameCol[dbdir;`master;`cusip;`cusipNew];
    assert.match[cols get .Q.dd[dbdir;`master];@[colNames;colNames?`cusip;:;`cusipNew]];
 };

testRenameColSplay:{[]
    initGenData[dbdir; `splayed];

    assert.fail[
        dbmaint.renameCol;
        (dbdir;`daily;`nonExistingCol;`nonExistingColCopy);
        "kdb+ object nonExistingCol not found at: ", 1_string .Q.dd[dbdir;`daily]
    ];

    assert.fail[
        dbmaint.renameCol;
        (dbdir;`daily;`open;`close);
        "Column close exists in ", 1_string .Q.dd[dbdir;`daily]
    ];

    colNames: get .Q.dd[dbdir;`daily`.d];
    dbmaint.renameCol[dbdir;`daily;`open;`openNew];
    assert.match[get .Q.dd[dbdir;`daily`.d]; @[colNames;colNames?`open;:;`openNew]];

    // Copy nested - should copy associated # file
    colNames: get .Q.dd[dbdir;`master`.d];
    dbmaint.renameCol[dbdir;`master;`description;`descriptionCopy];
    assert.match[get .Q.dd[dbdir;`master`.d]; @[colNames;colNames?`description;:;`descriptionCopy]];
    assert.true all (`descriptionCopy,`$"descriptionCopy#") in key .Q.dd[dbdir;`master];
 };

testRenameColPart:{[]
    initGenData[dbdir; `flat];

    res: .[dbmaint.renameCol; (dbdir;`trade;`nonExistingCol;`nonExistingColCopy); ::];
    if[not res like "kdb+ object nonExistingCol not found at: *";
        fail "ASSERT FAIL | Expected error message to contain 'kdb+ object nonExistingCol not found at: *', but got ", res];

    assert.fail[
        dbmaint.renameCol;
        (dbdir;`trade;`size;`price);
        "Column price exists in ", 1_string .Q.dd[dbdir;start, `trade]
    ];

    dbmaint.renameCol[dbdir;`trade;`size;`sizeNew];
    {
        assert.true `sizeNew in key .Q.dd[dbdir;x,`trade];
        assert.true `sizeNew in get .Q.dd[dbdir;x,`trade`.d];
        assert.false `size in key .Q.dd[dbdir;x,`trade];
        assert.false `size in get .Q.dd[dbdir;x,`trade`.d];
    } each start + til 1+ end - start;
 };

testReorderColsFlat:{[]
    initGenData[dbdir; `flat];

    colNames: cols get .Q.dd[dbdir;`master];

    assert.fail[
        dbmaint.reorderCols;
        (dbdir;`master;`unknownCol);
        "Unknown column(s): unknownCol"
    ];

    dbmaint.reorderCols[dbdir;`master;reverse colNames];
    assert.match[cols get .Q.dd[dbdir;`master]; reverse colNames];

    // Only named columns are reordered
    colNames: cols get .Q.dd[dbdir;`master];
    dbmaint.reorderCols[dbdir;`master;-3#colNames];
    assert.match[cols get .Q.dd[dbdir;`master]; (-3#colNames), -3_colNames];
 };

testReorderColsSplay:{[]
    initGenData[dbdir; `splayed];

    assert.fail[
        dbmaint.reorderCols;
        (dbdir;`master;`unknownCol);
        "Unknown column(s): unknownCol"
    ];

    colNames: get .Q.dd[dbdir;`master`.d];
    dbmaint.reorderCols[dbdir;`master;reverse colNames];
    assert.match[get .Q.dd[dbdir;`master`.d]; reverse colNames];

    // Only named columns are reordered
    colNames: get .Q.dd[dbdir;`daily`.d];
    dbmaint.reorderCols[dbdir;`daily;-2#colNames];
    assert.match[get .Q.dd[dbdir;`daily`.d]; (-2#colNames), -2_colNames];
 };

testReorderColsPart:{[]
    initGenData[dbdir; `splayed];

    assert.fail[
        dbmaint.reorderCols;
        (dbdir;`trade;`unknownCol);
        "Unknown column(s): unknownCol"
    ];

    colNames: get .Q.dd[dbdir;start,`trade`.d];
    dbmaint.reorderCols[dbdir;`trade;reverse colNames];
    colNames {assert.match[get .Q.dd[dbdir; y,`trade`.d]; reverse x]}/: start + til 1+ end - start;

    // Only named columns are reordered
    colNames: get .Q.dd[dbdir;start,`trade`.d];
    dbmaint.reorderCols[dbdir;`trade;-2#colNames];
    colNames {assert.match[get .Q.dd[dbdir; y,`trade`.d]; (-2#x), -2_x]}/: start + til 1+ end - start;
 };


testFnColFlat:{[]
    initGenData[dbdir; `flat];

    assert.fail[
        dbmaint.fnCol;
        (dbdir;`master;`nonExistingCol;10*);
        "Column nonExistingCol does not exist in master"
    ];

    issueprice:get[.Q.dd[dbdir;`master]]`issueprice;
    description:get[.Q.dd[dbdir;`master]]`description;

    dbmaint.fnCol[dbdir;`master;`issueprice;10*];
    dbmaint.fnCol[dbdir;`master;`description;upper];
    assert.match[10*issueprice;get[.Q.dd[dbdir;`master]]`issueprice];
    assert.match[upper description;get[.Q.dd[dbdir;`master]]`description];
 };

testFnColSplay:{[]
    initGenData[dbdir; `flat];

    assert.fail[
        dbmaint.fnCol;
        (dbdir;`daily;`nonExistingCol;10*);
        "kdb+ object nonExistingCol not found at: ", 1_string .Q.dd[dbdir;`daily]
    ];

    open:get .Q.dd[dbdir;`daily`open];

    dbmaint.fnCol[dbdir;`daily;`open;10*];
    assert.match[10*open;get .Q.dd[dbdir;`daily`open]];
 };

testFnColPart:{[]
    initGenData[dbdir; `flat];

    res: .[dbmaint.fnCol; (dbdir;`trade;`nonExistingCol;10*); ::];
    if[not res like "kdb+ object nonExistingCol not found at: *";
        fail "ASSERT FAIL | Expected error message to contain 'kdb+ object nonExistingCol'"];

    size:{get .Q.dd[dbdir;(x;`trade;`size)]} each start + til 1+ end - start;

    dbmaint.fnCol[dbdir;`trade;`size;10*];
    size {
        assert.match[10*x;get .Q.dd[dbdir;(y;`trade;`size)]];
    }' start + til 1+ end - start;
 };

testCastColFlat:{[]
    initGenData[dbdir; `flat];

    assert.fail[
        dbmaint.castCol;
        (dbdir;`master;`nonExistingCol;"f");
        "Column nonExistingCol does not exist in master"
    ];

    issueprice:get[.Q.dd[dbdir;`master]]`issueprice;
    assert.eq[9h;type issueprice];
    dbmaint.castCol[dbdir;`master;`issueprice;"e"];
    assert.match[`real$issueprice;get[.Q.dd[dbdir;`master]]`issueprice];
 };

testCastColSplay:{[]
    initGenData[dbdir; `flat];

    assert.fail[
        dbmaint.castCol;
        (dbdir;`daily;`nonExistingCol;"f");
        "kdb+ object nonExistingCol not found at: ", 1_string .Q.dd[dbdir;`daily]
    ];

    open:get .Q.dd[dbdir;`daily`open];
    assert.eq[9h;type open];
    dbmaint.castCol[dbdir;`daily;`open;"e"];
    assert.match[`real$open;get .Q.dd[dbdir;`daily`open]];
 };

testCastColPart:{[]
    initGenData[dbdir; `flat];

    res: .[dbmaint.castCol; (dbdir;`trade;`nonExistingCol;"f"); ::];
    if[not res like "kdb+ object nonExistingCol not found at: *";
        fail "ASSERT FAIL | Expected error message to contain 'kdb+ object nonExistingCol'"];

    size:{get .Q.dd[dbdir;(x;`trade;`size)]} each start + til 1+ end - start;
    {assert.eq[7h;type x]} each size;
    dbmaint.castCol[dbdir;`trade;`size;"e"];
    size {
        assert.match[`real$x;get .Q.dd[dbdir;(y;`trade;`size)]];
    }' start + til 1+ end - start;
 };

testAttrFlat:{[]
    initGenData[dbdir; `flat];

    assert.fail[
        dbmaint.setAttr;
        (dbdir;`master;`nonExistingCol;`s);
        "Column nonExistingCol does not exist in master"
    ];

    assert.eq[`;attr get[.Q.dd[dbdir;`master]]`cusip];
    dbmaint.setAttr[dbdir;`master;`cusip;`g];
    assert.eq[`g;attr get[.Q.dd[dbdir;`master]]`cusip];

    dbmaint.rmAttr[dbdir;`master;`cusip];
    assert.eq[`;attr get[.Q.dd[dbdir;`master]]`cusip];
 };

testAttrSplay:{[]
    initGenData[dbdir; `flat];

    assert.fail[
        dbmaint.setAttr;
        (dbdir;`daily;`nonExistingCol;`s);
        "kdb+ object nonExistingCol not found at: ", 1_string .Q.dd[dbdir;`daily]
    ];

    assert.eq[`;attr get .Q.dd[dbdir;`daily`open]];
    dbmaint.setAttr[dbdir;`daily;`open;`g];
    assert.eq[`g;attr get .Q.dd[dbdir;`daily`open]];

    dbmaint.rmAttr[dbdir;`daily;`open];
    assert.eq[`;attr get .Q.dd[dbdir;`daily`open]];
 };

testAttrPart:{[]
    initGenData[dbdir; `flat];

    res: .[dbmaint.setAttr; (dbdir;`trade;`nonExistingCol;`s); ::];
    if[not res like "kdb+ object nonExistingCol not found at: *";
        fail "ASSERT FAIL | Expected error message to contain 'kdb+ object nonExistingCol'"];

    {assert.eq[`;attr get .Q.dd[dbdir;(x;`trade;`size)]]} each start + til 1+ end - start;
    dbmaint.setAttr[dbdir;`trade;`size;`g];
    {assert.eq[`g;attr get .Q.dd[dbdir;(x;`trade;`size)]]} each start + til 1+ end - start;

    dbmaint.rmAttr[dbdir;`trade;`size];
    {assert.eq[`;attr get .Q.dd[dbdir;(x;`trade;`size)]]} each start + til 1+ end - start;
 };

testAddMissingColsPart:{[]
    initGenData[dbdir; `flat];

    colNames: get .Q.dd[dbdir;start,`trade`.d];
    goodTdir:`$string[.Q.dd[dbdir;start,`trade]],"Copy";
    rcopy[.Q.dd[dbdir;start,`trade];goodTdir];

    // Single missing column
    dbmaint.delCol[dbdir;`trade;`size];
    assert.match[dbmaint.listCols[dbdir;`trade]; colNames except `size];
    dbmaint.addMissingCols[dbdir;`trade;goodTdir];
    assert.match[dbmaint.listCols[dbdir;`trade]; colNames];
    assert.match[2_-21!.Q.dd[dbdir;start,`trade`size]; 2_-21!.Q.dd[goodTdir;`size]];

    // Multiple missing columns
    dbmaint.delCol[dbdir;`trade;] each `size`price`stop;
    assert.match[dbmaint.listCols[dbdir;`trade]; colNames except `size`price`stop];
    dbmaint.addMissingCols[dbdir;`trade;goodTdir];
    assert.match[dbmaint.listCols[dbdir;`trade]; colNames];
    assert.match[2_-21!.Q.dd[dbdir;start,`trade`size]; 2_-21!.Q.dd[goodTdir;`size]];
    assert.match[2_-21!.Q.dd[dbdir;start,`trade`price]; 2_-21!.Q.dd[goodTdir;`price]];
    assert.match[2_-21!.Q.dd[dbdir;start,`trade`stop]; 2_-21!.Q.dd[goodTdir;`stop]];
 };

testAddMissingColsPartCompr:{[]
    initGenData[dbdir; `flat];

    colNames: get .Q.dd[dbdir;start,`trade`.d];
    goodTdir:`$string[.Q.dd[dbdir;start,`trade]],"Copy";
    rcopy[.Q.dd[dbdir;start,`trade];goodTdir];
    (.Q.dd[goodTdir;`size], 17, 2, 6) set get .Q.dd[goodTdir;`size];
    (.Q.dd[goodTdir;`price], 17, 2, 5) set get .Q.dd[goodTdir;`price];
    (.Q.dd[goodTdir;`stop], 17, 2, 4) set get .Q.dd[goodTdir;`stop];


    // Single missing column
    dbmaint.delCol[dbdir;`trade;`size];
    assert.match[dbmaint.listCols[dbdir;`trade]; colNames except `size];
    dbmaint.addMissingCols[dbdir;`trade;goodTdir];
    assert.match[dbmaint.listCols[dbdir;`trade]; colNames];
    assert.match[2_-21!.Q.dd[dbdir;start,`trade`size]; 2_-21!.Q.dd[goodTdir;`size]];

    // Multiple missing columns
    dbmaint.delCol[dbdir;`trade;] each `size`price`stop;
    assert.match[dbmaint.listCols[dbdir;`trade]; colNames except `size`price`stop];
    dbmaint.addMissingCols[dbdir;`trade;goodTdir];
    assert.match[dbmaint.listCols[dbdir;`trade]; colNames];
    assert.match[2_-21!.Q.dd[dbdir;start,`trade`size]; 2_-21!.Q.dd[goodTdir;`size]];
    assert.match[2_-21!.Q.dd[dbdir;start,`trade`price]; 2_-21!.Q.dd[goodTdir;`price]];
    assert.match[2_-21!.Q.dd[dbdir;start,`trade`stop]; 2_-21!.Q.dd[goodTdir;`stop]];
 };



testAddTabFlat:{[]
    initGenData[dbdir; `flat];

    schemaFlat:([] sym :`$(); floatCol:"f"$(); intCol:"i"$());
    dbmaint.addTab[dbdir;`flatTable; schemaFlat; `flat];
    assert.match[schemaFlat; get .Q.dd[dbdir; `flatTable]];

 };

testAddTabSplay:{[]
    initGenData[dbdir; `splayed];

    schemaSplay:([] sym :`$(); realCol:"e"$(); longCol:"j"$());
    dbmaint.addTab[dbdir;`splayedTable; schemaSplay;`splayed];
    assert.true `splayedTable in key dbdir;
    assert.match[dbmaint.listCols[dbdir;`splayedTable]; cols schemaSplay];
 };

testAddTabSplayComprList:{[]
    initGenData[dbdir; `splayed];

    schemaSplay:([] sym :`$(); realCol:"e"$(); longCol:"j"$());
    dbmaint.addTab[dbdir;`splayedTable; schemaSplay;`splayed; ([compparam: 17 2 6])];
    assert.true `splayedTable in key dbdir;
    assert.match[dbmaint.listCols[dbdir;`splayedTable]; cols schemaSplay];
    assert.match[2 17 6i; -3 sublist value -21!.Q.dd[dbdir;`splayedTable`sym]];
    assert.match[2 17 6i; -3 sublist value -21!.Q.dd[dbdir;`splayedTable`realCol]];
    assert.match[2 17 6i; -3 sublist value -21!.Q.dd[dbdir;`splayedTable`longCol]];
 };

testAddTabSplayComprDict:{[]
    initGenData[dbdir; `splayed];

    schemaSplay:([] sym :`$(); realCol:"e"$(); longCol:"j"$());
    dbmaint.addTab[dbdir;`splayedTable; schemaSplay;`splayed; ([compparam: ``realCol`longCol!(0 0 0; 17 2 6; 16 2 5)])];
    assert.true `splayedTable in key dbdir;
    assert.match[dbmaint.listCols[dbdir;`splayedTable]; cols schemaSplay];
    assert.match[([]); -21!.Q.dd[dbdir;`splayedTable`sym]];
    assert.match[2 17 6i; -3 sublist value -21!.Q.dd[dbdir;`splayedTable`realCol]];
    assert.match[2 16 5i; -3 sublist value -21!.Q.dd[dbdir;`splayedTable`longCol]];
 };

testAddTabPart:{[]
    initGenData[dbdir; `flat];

    schema:([] sym:`$(); ap:"f"$(); bp:"f"$());
    dbmaint.addTab[dbdir;`quote; schema;`partitioned;([domain: `sym])];
    {assert.true `quote in key .Q.dd[dbdir;x]} each start + til 1+ end - start;
    assert.match[dbmaint.listCols[dbdir;`quote]; cols schema];
 };

testDelTabFlat:{[]
    initGenData[dbdir; `flat];

    res: .[dbmaint.delTab; (dbdir;`nonExistingTab); ::];
    if[not res like "kdb+ object not found at: *";
        fail "ASSERT FAIL | Expected error message to contain 'kdb+ object not found at: *', but got ", res];

    dbmaint.delTab[dbdir;`master];
    assert.false `master in key dbdir;
 };

testDelTabSplay:{[]
    initGenData[dbdir; `splayed];

    dbmaint.delTab[dbdir;`master];
    assert.false `master in key dbdir;
 };

testDelTabPart:{[]
    initGenData[dbdir; `splayed];

    dbmaint.delTab[dbdir;`trade];
    {assert.false `trade in key .Q.dd[dbdir;x]} each start + til 1+ end - start;
 };

testRenameTabFlat:{[]
    initGenData[dbdir; `flat];

    assert.fail[
        dbmaint.renameTab;
        (dbdir;`master;`master);
        "New table name must be different from old table name"
    ];

    res: .[dbmaint.renameTab; (dbdir;`nonExistingTab;`newTab); ::];
    if[not res like "kdb+ object not found at: *";
        fail "ASSERT FAIL | Expected error message to contain 'kdb+ object not found at: *', but got ", res];

    assert.fail[
        dbmaint.renameTab;
        (dbdir;`master;`exnames);
        "kdb+ object exnames found at: ", 1_string dbdir
    ];
    dbmaint.renameTab[dbdir;`master;`masterRenamed];
    assert.false `master in key dbdir;
    assert.true `masterRenamed in key dbdir;

 };
testRenameTabSplay:{[]
    initGenData[dbdir; `splayed];

    res: .[dbmaint.renameTab; (dbdir;`nonExistingTab;`newTab); ::];
    if[not res like "kdb+ object not found at: *";
        fail "ASSERT FAIL | Expected error message to contain 'kdb+ object not found at: *', but got ", res];

    assert.fail[
        dbmaint.renameTab;
        (dbdir;`master;`exnames);
        "kdb+ object exnames found at: ", 1_string dbdir
    ];
    dbmaint.renameTab[dbdir;`master;`masterRenamed];
    assert.false `master in key dbdir;
    assert.true `masterRenamed in key dbdir;
 };

testRenameTabPart:{[]
    rmrf dbdir;
    buildPersistedDB[dbdir; ([tbls: `trade`quote`daily; start; end; mastertype: `splayed])];

    res: .[dbmaint.renameTab; (dbdir;`nonExistingTab;`newTab); ::];
    if[not res like "kdb+ object not found at: *";
        fail "ASSERT FAIL | Expected error message to contain 'kdb+ object not found at: *', but got ", res];

    res: .[dbmaint.renameTab; (dbdir;`trade;`quote); ::];
    if[not res like "kdb+ object found at: *";
        fail "ASSERT FAIL | Expected error message to contain 'kdb+ object found at: *', but got ", res];

    dbmaint.renameTab[dbdir;`trade;`tradeRenamed];
    {assert.false `trade in key .Q.dd[dbdir;x]} each start + til 1+ end - start;
    {assert.true `tradeRenamed in key .Q.dd[dbdir;x]} each start + til 1+ end - start;
 };

testCopyTabFlat:{[]
    initGenData[dbdir; `flat];

    assert.fail[
        dbmaint.copyTab;
        (dbdir;`master;`master);
        "Target table name must be different from source table name"
    ];

    res: .[dbmaint.copyTab; (dbdir;`nonExistingTab;`newTab); ::];
    if[not res like "kdb+ object not found at: *";
        fail "ASSERT FAIL | Expected error message to contain 'kdb+ object not found at: *', but got ", res];

    assert.fail[
        dbmaint.copyTab;
        (dbdir;`master;`exnames);
        "kdb+ object exnames found at: ", 1_string dbdir
    ];
    dbmaint.copyTab[dbdir;`master;`masterCopied];
    assert.true `master in key dbdir;
    assert.true `masterCopied in key dbdir;

 };
testCopyTabSplay:{[]
    initGenData[dbdir; `splayed];

    res: .[dbmaint.copyTab; (dbdir;`nonExistingTab;`newTab); ::];
    if[not res like "kdb+ object not found at: *";
        fail "ASSERT FAIL | Expected error message to contain 'kdb+ object not found at: *', but got ", res];

    assert.fail[
        dbmaint.copyTab;
        (dbdir;`master;`exnames);
        "kdb+ object exnames found at: ", 1_string dbdir
    ];
    dbmaint.copyTab[dbdir;`master;`masterCopied];
    assert.true `master in key dbdir;
    assert.true `masterCopied in key dbdir;
 };

testCopyTabPart:{[]
    rmrf dbdir;
    buildPersistedDB[dbdir; ([tbls: `trade`quote`daily; start; end; mastertype: `splayed])];

    res: .[dbmaint.copyTab; (dbdir;`nonExistingTab;`newTab); ::];
    if[not res like "kdb+ object not found at: *";
        fail "ASSERT FAIL | Expected error message to contain 'kdb+ object not found at: *', but got ", res];

    res: .[dbmaint.copyTab; (dbdir;`trade;`quote); ::];
    if[not res like "kdb+ object found at: *";
        fail "ASSERT FAIL | Expected error message to contain 'kdb+ object found at: *', but got ", res];

    dbmaint.copyTab[dbdir;`trade;`tradeCopied];
    {assert.true `trade in key .Q.dd[dbdir;x]} each start + til 1+ end - start;
    {assert.true `tradeCopied in key .Q.dd[dbdir;x]} each start + til 1+ end - start;
 };

testCheckTabExistence[]
testCheckColFiles[]
testCheckColFilesNested[]
testCheckDotDEquality[]
testListCols[]

testAddTabFlat[]
testAddTabSplay[]
testAddTabSplayComprList[]
testAddTabSplayComprDict[]
testAddTabPart[]

testDelTabFlat[]
testDelTabSplay[]
testDelTabPart[]

testRenameTabFlat[]
testRenameTabSplay[]
testRenameTabPart[]

testCopyTabFlat[]
testCopyTabSplay[]
testCopyTabPart[]

testAddColFlat[]
testAddColSplay[]
testAddColSplayCompr[]
testAddColPart[]

testDelColFlat[]
testDelColSplay[]
testDelColPart[]

testCopyColFlat[]
testCopyColSplay[]
testCopyColPart[]

testRenameColFlat[]
testRenameColSplay[]
testRenameColPart[]

testReorderColsFlat[]
testReorderColsSplay[]
testReorderColsPart[]

testFnColFlat[]
testFnColSplay[]
testFnColPart[]

testCastColFlat[]
testCastColSplay[]
testCastColPart[]

testAttrFlat[]
testAttrSplay[]
testAttrPart[]

testAddMissingColsPart[]
testAddMissingColsPartCompr[]

rmrf dbdir

-1 "All tests passed";

if[not "-debug" in .z.x; exit 0]