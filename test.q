dbmaint: use `$"..dbmaint";

dbdir: hsym `$first .z.x
splayDB:.Q.dd[dbdir;`splayDB];
partDB:.Q.dd[dbdir;`partDB];
splayTdir:.Q.dd[splayDB;`trade];

partDates:.z.d-1 0;
partTdirs:{.Q.dd[partDB;x,`trade]} each partDates;

fail: {-2 x;'`failed}

init:{[]
    rmrf splayDB;
    rmrf partDB;
    mkdir splayDB;
    mkdir partDB;

    .z.m.trade:([]
        time:5#.z.P;
        sym:`IBM`AMZN`GOOGL`META`SPOT;
        size:1 2 3 4 5;
        price:10 20 30 40 50f;
        company:(
            "International Business Machines Corporation";
            "Amazon.com, Inc.";
            "Alphabet Inc.";
            "Meta Platforms, Inc.";
            "Spotify Technology S.A."
        );
        moves:3 cut -5+15?10
    );

    .Q.dd[splayDB;`trade`] set .Q.en[splayDB;.z.m.trade];

    {[db;dt;tname]
        .Q.dd[db;dt,tname,`] set .Q.en[db;.z.m tname]
    }[partDB;;`trade] each partDates;

    delete trade from `.;
 };

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

testListCols:{[]
    init[];

    colNames:`time`sym`size`price`company`moves;
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames];
    assert.match[dbmaint.listCols[partDB;`trade]; colNames];
    assert.match[dbmaint.listCols[`:nonExistingDB;`trade]; `$()];
    assert.match[dbmaint.listCols[splayDB;`nonExistingTable]; `$()];
 };

testAddColSplay:{[]
    init[];

    // No affect since column already exists
    colNames:`time`sym`size`price`company`moves;
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames];
    dbmaint.addCol[splayDB;`trade;`size;0N];
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames];

    dbmaint.addCol[splayDB;`trade;`newCol;0N];
    assert.true `newCol in key splayTdir;
    assert.true `newCol in get splayTdir,`.d;
    assert.true all 0N=get splayTdir,`newCol;
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames,`newCol];
 };

testAddColPart:{[]
    init[];

    // No affect since column already exists
    colNames:`time`sym`size`price`company`moves;
    assert.match[dbmaint.listCols[partDB;`trade]; colNames];
    dbmaint.addCol[partDB;`trade;`size;0N];
    assert.match[dbmaint.listCols[partDB;`trade]; colNames];

    dbmaint.addCol[partDB;`trade;`newCol;0N];
    {
        assert.true `newCol in key x;
        assert.true `newCol in get x,`.d;
        assert.true all 0N=get x,`newCol
    } each partTdirs;

    dbmaint.addCol[partDB;`trade;`newSymCol;`symvalues;`sym];
    {
        assert.true `newSymCol in key x;
        assert.true `newSymCol in get x,`.d;
        assert.true all `symvalues=get x,`newSymCol
    } each partTdirs;
    assert.match[dbmaint.listCols[partDB;`trade]; colNames,`newCol`newSymCol];
 };

testDelColSplay:{[]
    init[];

    // No affect since column does not exist
    colNames:`time`sym`size`price`company`moves;
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames];
    dbmaint.delCol[splayDB;`trade;`nonExistingCol];
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames];

    dbmaint.delCol[splayDB;`trade;`size];
    assert.false `size in key splayTdir;
    assert.false `size in get splayTdir,`.d;
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames except `size];

    // Delete nested - should delete associated # file
    assert.true all (`company,`$"company#") in key splayTdir;
    dbmaint.delCol[splayDB;`trade;`company];
    assert.false all (`company,`$"company#") in key splayTdir;
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames except `size`company];
 };

testDelColPart:{[]
    init[];

    // No affect since column does not exist
    colNames:`time`sym`size`price`company`moves;
    assert.match[dbmaint.listCols[partDB;`trade]; colNames];
    dbmaint.delCol[partDB;`trade;`nonExistingCol];
    assert.match[dbmaint.listCols[partDB;`trade]; colNames];

    dbmaint.delCol[partDB;`trade;`size];
    {
        assert.false `size in key x;
        assert.false `size in get x,`.d;
    } each partTdirs;
    assert.match[dbmaint.listCols[partDB;`trade]; colNames except `size];

    // Delete nested - should delete associated # file
    {assert.true all (`company,`$"company#") in key x} each partTdirs;
    dbmaint.delCol[partDB;`trade;`company];
    {assert.false all (`company,`$"company#") in key x} each partTdirs;
    assert.match[dbmaint.listCols[partDB;`trade]; colNames except `size`company];
 };

testCopyColSplay:{[]
    init[];

    // No affect since price already exists
    colNames:`time`sym`size`price`company`moves;
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames];
    dbmaint.copyCol[splayDB;`trade;`size;`price];
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames];

    dbmaint.copyCol[splayDB;`trade;`size;`sizeCopy];
    assert.true `sizeCopy in key splayTdir;
    assert.true `sizeCopy in get splayTdir,`.d;
    assert.match[get splayTdir,`size;get splayTdir,`sizeCopy];
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames,`sizeCopy];

    // Copy nested - should copy associated # file
    dbmaint.copyCol[splayDB;`trade;`company;`companyCopy];
    assert.true all (`companyCopy,`$"companyCopy#") in key splayTdir;
    assert.match[get splayTdir,`companyCopy;get splayTdir,`companyCopy];
    assert.match[get splayTdir,`$"companyCopy#";get splayTdir,`$"companyCopy#"];
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames,`sizeCopy`companyCopy];
 };

testCopyColPart:{[]
    init[];

    // No affect since price already exists
    colNames:`time`sym`size`price`company`moves;
    assert.match[dbmaint.listCols[partDB;`trade]; colNames];
    dbmaint.copyCol[partDB;`trade;`size;`price];
    assert.match[dbmaint.listCols[partDB;`trade]; colNames];

    dbmaint.copyCol[partDB;`trade;`size;`sizeCopy];
    {
        assert.true `sizeCopy in key x;
        assert.true `sizeCopy in get x,`.d;
        assert.match[get x,`size;get x,`sizeCopy];
    } each partTdirs;
    assert.match[dbmaint.listCols[partDB;`trade]; colNames,`sizeCopy];

    // Copy nested - should copy associated # file
    dbmaint.copyCol[partDB;`trade;`company;`companyCopy];
    {
        assert.true all (`companyCopy,`$"companyCopy#") in key x;
        assert.match[get x,`companyCopy;get x,`companyCopy];
        assert.match[get x,`$"companyCopy#";get x,`$"companyCopy#"];
    } each partTdirs;
    assert.match[dbmaint.listCols[partDB;`trade]; colNames,`sizeCopy`companyCopy];
 };

testHasCol:{[]
    init[];

    assert.true dbmaint.hasCol[splayDB;`trade;`size];
    assert.false dbmaint.hasCol[splayDB;`trade;`nonExistingCol];
    assert.true dbmaint.hasCol[partDB;`trade;`size];
    assert.false dbmaint.hasCol[partDB;`trade;`nonExistingCol];
 };

testRenameColSplay:{[]
    init[];

    // No affect since price already exists
    colNames:`time`sym`size`price`company`moves;
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames];
    dbmaint.renameCol[splayDB;`trade;`size;`price];
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames];

    sizeData:get splayTdir,`size;
    dbmaint.renameCol[splayDB;`trade;`size;`sizeRenamed];
    assert.true `sizeRenamed in key splayTdir;
    assert.true `sizeRenamed in get splayTdir,`.d;
    assert.false `size in key splayTdir;
    assert.false `size in get splayTdir,`.d;
    assert.match[sizeData;get splayTdir,`sizeRenamed];
    colNames:@[colNames;where colNames=`size;:;`sizeRenamed];
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames];

    // Rename nested - should rename associated # file
    companyData:get splayTdir,`company;
    companyHashData:get splayTdir,`$"company#";
    dbmaint.renameCol[splayDB;`trade;`company;`companyRenamed];
    assert.true all (`companyRenamed,`$"companyRenamed#") in key splayTdir;
    assert.match[companyData;get splayTdir,`companyRenamed];
    assert.match[companyHashData;get splayTdir,`$"companyRenamed#"];
    colNames:@[colNames;where colNames=`company;:;`companyRenamed];
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames];
 };

testRenameColPart:{[]
    init[];

    // No affect since price already exists
    colNames:`time`sym`size`price`company`moves;
    assert.match[dbmaint.listCols[partDB;`trade]; colNames];
    dbmaint.renameCol[partDB;`trade;`size;`price];
    assert.match[dbmaint.listCols[partDB;`trade]; colNames];

    sizeData:get partTdirs[0],`size;
    dbmaint.renameCol[partDB;`trade;`size;`sizeRenamed];
    {
        assert.true `sizeRenamed in key x;
        assert.true `sizeRenamed in get x,`.d;
        assert.false `size in key x;
        assert.false `size in get x,`.d;
        assert.match[y;get x,`sizeRenamed];
    }[;sizeData] each partTdirs;
    colNames:@[colNames;where colNames=`size;:;`sizeRenamed];
    assert.match[dbmaint.listCols[partDB;`trade]; colNames];

    // Rename nested - should rename associated # file
    companyData:get partTdirs[0],`company;
    companyHashData:get partTdirs[0],`$"company#";
    dbmaint.renameCol[partDB;`trade;`company;`companyRenamed];
    {
        assert.true all (`companyRenamed,`$"companyRenamed#") in key x;
        assert.match[y;get x,`companyRenamed];
        assert.match[z;get x,`$"companyRenamed#"];
    }[;companyData;companyHashData] each partTdirs;
    colNames:@[colNames;where colNames=`company;:;`companyRenamed];
    assert.match[dbmaint.listCols[partDB;`trade]; colNames];
 };

testReorderColsSplay:{[]
    init[];

    colNames:`time`sym`size`price`company`moves;
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames];

    assert.fail[
        dbmaint.reorderCols;
        (splayDB;`trade;colNames,`unknownCol);
        "Unknown column(s): unknownCol"
    ];

    dbmaint.reorderCols[splayDB;`trade;reverse colNames];
    assert.match[dbmaint.listCols[splayDB;`trade]; reverse colNames];

    // Only named columns are reordered
    dbmaint.reorderCols[splayDB;`trade;`sym`company`time];
    assert.match[dbmaint.listCols[splayDB;`trade]; `sym`company`time`moves`price`size];
 };

testReorderColsPart:{[]
    init[];

    colNames:`time`sym`size`price`company`moves;
    assert.match[dbmaint.listCols[partDB;`trade]; colNames];

    assert.fail[
        dbmaint.reorderCols;
        (partDB;`trade;colNames,`unknownCol);
        "Unknown column(s): unknownCol"
    ];

    dbmaint.reorderCols[partDB;`trade;reverse colNames];
    assert.match[dbmaint.listCols[partDB;`trade]; reverse colNames];

    // Only named columns are reordered
    dbmaint.reorderCols[partDB;`trade;`sym`company`time];
    assert.match[dbmaint.listCols[partDB;`trade]; `sym`company`time`moves`price`size];
 };

testFnColSplay:{[]
    init[];

    // No affect since column does not exist
    dbmaint.fnCol[splayDB;`trade;`nonExistingCol;10*];

    sizeData:get splayTdir,`size;
    dbmaint.fnCol[splayDB;`trade;`size;10*];
    assert.match[10*sizeData;get splayTdir,`size];

    companyData:get splayTdir,`company;
    dbmaint.fnCol[splayDB;`trade;`company;upper];
    assert.match[upper companyData;get splayTdir,`company];
 };

testFnColPart:{[]
    init[];

    // No affect since column does not exist
    dbmaint.fnCol[partDB;`trade;`nonExistingCol;10*];

    sizeData:get partTdirs[0],`size;
    companyData:get partTdirs[0],`company;

    dbmaint.fnCol[partDB;`trade;`size;10*];
    dbmaint.fnCol[partDB;`trade;`company;upper];
    {
        assert.match[10*y;get x,`size];
        assert.match[upper z;get x,`company];
    }[;sizeData;companyData] each partTdirs;

    priceData:get partTdirs[0],`price;
    dbmaint.fnCol[partDB;`trade;`price;neg;.z.d-1];
    assert.match[neg priceData;get partTdirs[0],`price];
    assert.match[priceData;get partTdirs[1],`price];
 };

testCastColSplay:{[]
    init[];

    // No affect since column does not exist
    dbmaint.castCol[splayDB;`trade;`nonExistingCol;10*];

    assert.eq[7h;type get splayTdir,`size];
    dbmaint.castCol[splayDB;`trade;`size;"f"];
    assert.eq[9h;type get splayTdir,`size];
 };

testCastColPart:{[]
    init[];

    // No affect since column does not exist
    dbmaint.castCol[partDB;`trade;`nonExistingCol;10*];

    {assert.eq[7h;type get x,`size]} each partTdirs;
    dbmaint.castCol[partDB;`trade;`size;"f"];
    {assert.eq[9h;type get x,`size]} each partTdirs;
 };

testAttrSplay:{[]
    init[];

    // No affect since column does not exist
    dbmaint.setAttr[splayDB;`trade;`nonExistingCol;`s];

    assert.eq[`;attr get splayTdir,`size];
    dbmaint.setAttr[splayDB;`trade;`size;`s];
    assert.eq[`s;attr get splayTdir,`size];

    dbmaint.rmAttr[splayDB;`trade;`size];
    assert.eq[`;attr get splayTdir,`size];
 };

testAttrPart:{[]
    init[];

    // No affect since column does not exist
    dbmaint.setAttr[partDB;`trade;`nonExistingCol;`s];

    {assert.eq[`;attr get x,`size]} each partTdirs;
    dbmaint.setAttr[partDB;`trade;`size;`s];
    {assert.eq[`s;attr get x,`size]} each partTdirs;

    dbmaint.rmAttr[partDB;`trade;`size];
    {assert.eq[`;attr get x,`size]} each partTdirs;
 };

testAddMissingColsSplay:{[]
    init[];

    colNames:`time`sym`size`price`company`moves;
    goodTdir:`$string[splayTdir],"Copy";
    rcopy[splayTdir;goodTdir];

    // Single missing column
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames];
    dbmaint.delCol[splayDB;`trade;`size];
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames except `size];
    dbmaint.addMissingCols[splayDB;`trade;goodTdir];
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames];

    // Multiple missing columns (including nested)
    dbmaint.delCol[splayDB;`trade;] each `size`price`company;
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames except `size`price`company];
    dbmaint.addMissingCols[splayDB;`trade;goodTdir];
    assert.match[dbmaint.listCols[splayDB;`trade]; colNames];
    assert.true all (`company,`$"company#") in key splayTdir;
 };

testAddMissingColsPart:{[]
    init[];

    colNames:`time`sym`size`price`company`moves;
    goodTdir:`$string[partTdirs 0],"Copy";
    rcopy[partTdirs 0;goodTdir];

    // Single missing column
    assert.match[dbmaint.listCols[partDB;`trade]; colNames];
    dbmaint.delCol[partDB;`trade;`size];
    assert.match[dbmaint.listCols[partDB;`trade]; colNames except `size];
    dbmaint.addMissingCols[partDB;`trade;goodTdir];
    assert.match[dbmaint.listCols[partDB;`trade]; colNames];

    // Multiple missing columns (including nested)
    dbmaint.delCol[partDB;`trade;] each `size`price`company;
    assert.match[dbmaint.listCols[partDB;`trade]; colNames except `size`price`company];
    dbmaint.addMissingCols[partDB;`trade;goodTdir];
    assert.match[dbmaint.listCols[partDB;`trade]; colNames];
    {assert.true all (`company,`$"company#") in key x} each partTdirs;
 };

testAddTabSplay:{[]
    init[];

    schema:([] sym:`$(); ap:"f"$(); bp:"f"$());
    assert.false `quote in key splayDB;

    dbmaint.addTab[splayDB;`sym;`quote;schema];
    assert.true `quote in key splayDB;
    assert.match[dbmaint.listCols[splayDB;`quote]; `sym`ap`bp];
 };

testAddTabPart:{[]
    init[];

    schema:([] sym:`$(); ap:"f"$(); bp:"f"$());
    {assert.false `quote in key .Q.dd[x;y]}[partDB;] each partDates;

    dbmaint.addTab[partDB;`sym;`quote;schema];
    {assert.true `quote in key .Q.dd[x;y]}[partDB;] each partDates;
    assert.match[dbmaint.listCols[partDB;`quote]; `sym`ap`bp];
 };

testDelTabSplay:{[]
    init[];

    assert.true `trade in key splayDB;
    dbmaint.delTab[splayDB;`trade];
    assert.false `trade in key splayDB;
 };

testDelTabPart:{[]
    init[];

    {assert.true `trade in key .Q.dd[x;y]}[partDB;] each partDates;
    dbmaint.delTab[partDB;`trade];
    {assert.false `trade in key .Q.dd[x;y]}[partDB;] each partDates;
 };

testRenameTabSplay:{[]
    init[];

    colNames:`time`sym`size`price`company`moves;

    assert.true `trade in key splayDB;
    dbmaint.renameTab[splayDB;`trade;`tradeRenamed];
    assert.false `trade in key splayDB;
    assert.true `tradeRenamed in key splayDB;
    assert.match[dbmaint.listCols[splayDB;`tradeRenamed]; colNames];
 };

testRenameTabPart:{[]
    init[];

    colNames:`time`sym`size`price`company`moves;

    {assert.true `trade in key .Q.dd[x;y]}[partDB;] each partDates;
    dbmaint.renameTab[partDB;`trade;`tradeRenamed];
    {assert.false `trade in key .Q.dd[x;y]}[partDB;] each partDates;
    {assert.true `tradeRenamed in key .Q.dd[x;y]}[partDB;] each partDates;
    assert.match[dbmaint.listCols[partDB;`tradeRenamed]; colNames];
 };

testListCols[]
testAddColSplay[]
testAddColPart[]
testDelColSplay[]
testDelColPart[]
testCopyColSplay[]
testCopyColPart[]
testHasCol[]
testRenameColSplay[]
testRenameColPart[]
testReorderColsSplay[]
testReorderColsPart[]
testFnColSplay[]
testFnColPart[]
testCastColSplay[]
testCastColPart[]
testAttrSplay[]
testAttrPart[]
testAddMissingColsSplay[]
testAddMissingColsPart[]
testAddTabSplay[]
testAddTabPart[]
testDelTabSplay[]
testDelTabPart[]
testRenameTabSplay[]
testRenameTabPart[]

rmrf splayDB
rmrf partDB

-1 "All tests passed";

exit 0