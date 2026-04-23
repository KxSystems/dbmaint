
/
    @file
        dbmaint.q

    @description
        Database Maintenance.
\


// @brief Check if a table exists in all partitions of a database.
// @param db string|symbol|file symbol Path to database root.
// @param tname symbol Table name.
checkTabExistence:{[db:getFSym;tname:`s]
    if[tname in key db; :1b];
    checkTablePathsExist buildTablePaths[db;tname];
    1b
 };


// @brief Check table partitions if column order files (`.d`) match column file list.
// i.e. table directory is not missing any column files
// and does not have unknown column files.
// @param db string|symbol|file symbol Path to database root.
// @param tname symbol Table name.
checkColFiles:{[db:getFSym;tname:`s]
    t:getTableType[db;tname];
    if[`flat ~ t; :0b];
    check1ColFiles each $[`splayed ~ t; enlist .Q.dd[db;tname];
        buildTablePaths[db;tname]];
    1b
 }

// @brief Check all table partitions if column order files (`.d`) files are the same.
// @param db string|symbol|file symbol Path to database root.
// @param tname symbol Table name.
checkDotDEquality:{[db:getFSym;tname:`s]
    if[not `partOrMissing ~ getTableType[db;tname]; 0b];
    d:differ get each .Q.dd[;`.d] each p:buildTablePaths[db;tname];
    if[1< sum d;
        '".d mismatch at: ", 1_string first 1_p where d];
    1b
 }

// @brief Add a new table to all partitions of a database.
// @param db string|symbol|file symbol Path to database root.
// @param tname symbol New table name.
// @param data table New table data.
// @param tabletype symbol `splayed`partOrMissing or `flat.
// @param opt dict optional parameters as a dictionary with keys:
//      - domain symbol Sym file (domain) name. Default: `sym. Only used if table has symbol columns. Otherwise ignored.
//      - compparam int[3]|dict Default: 0 0 0. Compression parameter passed to `set`.
addTab:('[{[p]
    if[not count[p] in 4 5; '"four or five parameters must be passed to addTab"];
    (db:getFSym;tname:`s;data; tabletype:`s):4#p;
    opt: ([domain:`sym; compparam: 0 0 0i]);
    if[5=count p; opt,:p 4;];

    if[tabletype ~ `flat;
        (.Q.dd[db;tname], $[99h ~ type opt`compparam;enlist;] opt`compparam) set data;
        :()];

    add1Tab[;db;opt `domain;data;"i"$opt`compparam] each $[tabletype~`splayed;
        enlist .Q.dd[db;tname];
        checkTablePathsNotExist buildTablePaths[db;tname]];
 };enlist]);

// @brief Delete a table from a database.
// @param db string|symbol|file symbol Path to database root.
// @param tname symbol Table name.
delTab:{[db:getFSym;tname:`s]
    t:getTableType[db;tname];
    if[t ~ `flat; hdel .Q.dd[db;tname]; :()];
    del1Tab peach $[`splayed ~ t;
        enlist .Q.dd[db;tname];
        checkTablePathsExist buildTablePaths[db;tname]]
  };

// @brief Rename a table.
// @param db string|symbol|file symbol Path to database root.
// @param old symbol Current table name.
// @param new symbol New table name.
renameTab:{[db:getFSym;old:`s;new:getName]
    if[old ~ new; '"New table name must be different from old table name"];
    if[old in key db;
        if[new in key db;
            '"kdb+ object ", string[new], " found at: ", 1_ string db];
        rename[.Q.dd[db;old]; .Q.dd[db;new]];
        :()];
    (rename .) each flip (
        checkTablePathsExist buildTablePaths[db;old];
        checkTablePathsNotExist buildTablePaths[db;new])
 };

// @brief Copy a table.
// @param db string|symbol|file symbol Path to database root.
// @param src symbol Current table name.
// @param dst symbol New table name.
copyTab:{[db:getFSym;src:`s;dst:getName]
    if[src ~ dst; '"Target table name must be different from source table name"];
    if[src in key db;
        if[dst in key db;
            '"kdb+ object ", string[dst], " found at: ", 1_ string db];
        copy[.Q.dd[db;src]; .Q.dd[db;dst]];
        :()];
    (copy .) each flip (
        checkTablePathsExist buildTablePaths[db;src];
        checkTablePathsNotExist buildTablePaths[db;dst])
 };

// @brief Reorder the columns across all partitions of a table.
// @param db string|symbol|file symbol Path to database root.
// @param tname symbol Table name.
// @param order symbols New ordering of the columns (some or all).
reorderCols:{[db:getFSym;tname:`s;order]
    order,:();
    t: getTableType[db;tname];
    if[t ~ `flat;
        verifyReorderCols[order;cols get db, tname];
        (.Q.dd[db;tname], getCompParam[.Q.dd[db;tname]]) set order xcols get db, tname;
        :()];
    paths: $[`splayed ~ t; enlist .Q.dd[db;tname]; checkTablePathsExist buildTablePaths[db;tname]];
    order verifyReorderCols/: get each paths,\: `.d;
    reorder1Cols[;order] peach paths
  };



// @brief Add a column to a database table.
// @param db string|symbol|file symbol Path to database root.
// @param tname symbol Table name.
// @param cname symbol Column name.
// @param default any Default value of the column.
// @param opt dict optional parameters as a dictionary with keys:
//      - domain symbol Sym file (domain) name. Default: `sym. Only used if table has symbol columns. Otherwise ignored.
//      - compparam int[3] Default: 0 0 0. Compression parameter passed to `set`.
addCol:('[{[p]
    if[not count[p] in 4 5; '"four or five parameters must be passed to addCol"];
    (db:getFSym;tname:getName;cname:`s;default):4#p;
    opt: ([domain:`sym; compparam: 0 0 0i]);
    if[5=count p; opt,:p 4;];
    t: getTableType[db;tname];
    if[t ~ `flat;
        tab: get db, tname;
        if[cname in cols tab;
            '"Column ", (string cname), " already exists in ", string tname];
        (.Q.dd[db;tname], opt`compparam) set @[tab; cname; :; (count tab)#enlist default];
        :()];
    if[11h=abs type default;
        default:.Q.dd[db;opt `domain]?default];
    add1Col[;cname;default;"i"$opt`compparam] peach checkColPathNotExist[cname] $[`splayed ~ t;
        enlist .Q.dd[db;tname]; checkTablePathsExist buildTablePaths[db;tname]];
 };enlist]);

// @brief Delete a column from a database table.
// @param db string|symbol|file symbol Path to database root.
// @param tname symbol Table name.
// @param cname symbol Column name.
delCol:{[db:getFSym;tname:`s;cname:`s]
    t:getTableType[db;tname];
    if[t ~ `flat;
        if[not cname in cols get db, tname;
            '"Column ", (string cname)," does not exist in ", string tname];
        .Q.dd[db;tname] set (enlist cname) _  get db, tname;
        :()];
    del1Col[;cname] peach checkColPathExist[cname] $[`splayed ~ t; enlist .Q.dd[db;tname];
      checkTablePathsExist buildTablePaths[db;tname]]
  };

// @brief Rename a column across all partitions of a table.
// @param db string|symbol|file symbol Path to database root.
// @param tname symbol Table name.
// @param old symbol Current column name.
// @param new symbol New column name.
renameCol: {[db:getFSym;tname:`s;old:`s;new:getName]
    if[old ~ new; '"New column name must be different from old column name"];
    t: getTableType[db;tname];
    if[t ~ `flat;
        if[not old in cols get db, tname;
            '"Column ", (string old)," does not exist in ", string tname];
        if[new in cols get db, tname;
            '"Column ", (string new)," exists in ", string tname];
        (.Q.dd[db;tname], getCompParam[.Q.dd[db;tname]]) set (enlist[old]!enlist new) xcol get db, tname;
        :()];
    rename1Col[;old;new] each checkColPathExist[old] $[`splayed ~ t;
        enlist .Q.dd[db;tname]; checkTablePathsExist buildTablePaths[db;tname]];
 };

// @brief Copy a column across all partitions of a table.
// @param db string|symbol|file symbol Path to database root.
// @param tname symbol Table name.
// @param srcCol symbol Column name whose data will be copied.
// @param dstCol symbol New column name that will be created.
copyCol:{[db:getFSym;tname:`s;srcCol:`s;dstCol:getName]
    if[srcCol ~ dstCol; '"Source and destination column names must be different"];
    t:getTableType[db;tname];
    if[t ~ `flat;
        if[not srcCol in cols get db, tname;
            '"Column ", (string srcCol)," does not exist in ", string tname];
        if[dstCol in cols get db, tname;
            '"Column ", (string dstCol)," exists in ", string tname];
        (.Q.dd[db;tname], getCompParam[.Q.dd[db;tname]]) set ![;();0b;(enlist dstCol)!enlist srcCol] get db, tname;
        :()];
    copy1Col[;srcCol;dstCol] each checkColPathExist[srcCol]
        $[`splayed ~ t; enlist .Q.dd[db;tname];
        checkTablePathsExist buildTablePaths[db;tname]];
 };

// @brief Apply a function to a column across all partitions of a table.
// @param db string|symbol|file symbol Path to database root.
// @param tname symbol Table name.
// @param cname symbol Column name.
// @param fn function Unary function to apply to the column.
// @param dates date|date[] Optional: date or list of dates to restrict to.
fnCol:('[{[p]
    if[not count[p] in 4 5; '"four or five parameters must be passed to fnCol"];
    (db:getFSym;tname:`s;cname:`s;fn):4#p;
    t: getTableType[db;tname];
    if[t ~ `flat;
        if[not cname in cols get db, tname;
            '"Column ", (string cname)," does not exist in ", string tname];
        (.Q.dd[db;tname], getCompParam[.Q.dd[db;tname]]) set ![;();0b;(enlist cname)!enlist (fn;cname)] get db, tname;
        :()];
    fn1Col[;cname;fn] peach checkColPathExist[cname] $[t ~ `splayed; enlist .Q.dd[db;tname];
        checkTablePathsExist buildTablePaths . (db;tname), $[5=count p;enlist p 4;()]];
    };enlist]);

// @brief Cast a column to a given type.
// @param db string|symbol|file symbol Path to database root.
// @param tname symbol Table name.
// @param cname symbol Column name.
// @param typ short|char|symbol Type to cast column to. Pass "string" to cast to string type.
// @param dates date|date[] Optional: date or list of dates to restrict to.
castCol:('[{[p]
    if[not count[p] in 4 5; '"four or five parameters must be passed to castCol"];
    fn: $[string ~ p 3; string; p[3]$];
    fnCol . (3#p),fn,$[5=count p;last p;()]
    };enlist]);

// @brief Set an attribute on a column.
// @param db string|symbol|file symbol Path to database root.
// @param tname symbol Table name.
// @param cname symbol Column name.
// @param attrb symbol Attribute (s, u, p, g).
// @param dates date|date[] Optional: date or list of dates to restrict to.
setAttr:('[{[p]
    if[not count[p] in 4 5; '"four or five parameters must be passed to setAttr"];
    fnCol . (3#p),(p[3]#),$[5=count p;last p;()]
    };enlist]);

// @brief Remove an attribute from a column.
// @param db string|symbol|file symbol Path to database root.
// @param tname symbol Table name.
// @param cname symbol Column name.
// @param dates date|date[] Optional: date or list of dates to restrict to.
rmAttr:('[{[p]
    if[not count[p] in 3 4; '"three or four parameters must be passed to rmAttr"];
    setAttr . (3#p),`,$[4=count p;last p;()]
    };enlist]);

// @brief Add missing columns across all partitions of a table.
// @param db string|symbol|file symbol Path to database root.
// @param tname symbol Table name.
// @param goodTdir string|symbol|file symbol Path of a table directory which has no missing columns.
addMissingCols:{[db:getFSym;tname:`s;goodTdir:getFSym]
    if[not `partOrMissing ~ getTableType[db;tname];
        '"addMissingCols is only applicable to partitioned tables"];
    add1MissingCols[;goodTdir] peach checkTablePathsExist buildTablePaths[db;tname] except goodTdir;
 };


// @brief List all column names of the given table.
// @param db string|symbol|file symbol Path to database root.
// @param tname symbol Table name.
// @return symbols Column names.
listCols:{[db:getFSym;tname:`s]
    t: getTableType[db;tname];
    if[t ~`flat; :cols get db, tname];
    getColNames $[t ~ `splayed; .Q.dd[db;tname];
        checkTablePathsExist .Q.dd[db; (last c where (c:key db) like "[0-9]*"), tname]]
  };

export:([
    checkTabExistence; checkColFiles; checkDotDEquality;
    addTab; delTab; renameTab; copyTab; reorderCols;
    addCol; delCol; renameCol; copyCol;
    fnCol; castCol; setAttr; rmAttr;
    addMissingCols; listCols
 ]);

getTableType:{[db:getFSym;tname:`s]
  if[tname in key db;
    :$[p~key p:.Q.dd[db;tname]; `flat; `splayed]];
  `partOrMissing
 };

// @brief Creates a file symbol from string, symbol or file symbol.
getFSym:{[path]
 hsym $[10h~type path;`$;] path
 };

// @brief Check a table directory if .d matches column file list,
// i.e. table directory is not missing any column files
// and does not have unknown column files.
// @param tdir fileSymbol Table directory.
check1ColFiles:{[tdir:`s]
    l1: get tdir, `.d;
    l2: (key tdir) except `.d;
    missing: l1 except l2;
    if[count missing; '"Missing column file(s): ","," sv string missing];

    unknown: l2 except l1;
    notlistcol: unknown where not unknown like "*#";
    if[count notlistcol; '"Unknown column file(s): ","," sv string notlistcol];
    listcol: unknown where unknown like "*#";
    unknown: (`$-1_' string listcol) except l1;
    if[count unknown; '"Unknown column file(s): ","," sv string unknown]
 }

// @brief Check whether a given name is valid (adheres to proper naming rules).
// @param name symbol Name to check.
// @return bool 1b if valid, 0b otherwise.
isValidName:{[name:`s] (name=.Q.id name) and not name in .Q.res,key`.q};

// @brief Check whether a given name is valid (adheres to proper naming rules). Signal error if not.
// @param name symbol Name to validate.
getName:{[name:`s] if[not isValidName name; '"Invalid name: ",string name];name};

checkPathsCommon:{[paths; check; str]
    missing: ((), paths) where (check key@) each (), paths;
    if[count missing; '"kdb+ object", str," found at: ",", " sv 1_' string missing];
    paths};

checkTablePathsExist:checkPathsCommon[;{0=count x};" not"];
checkTablePathsNotExist:checkPathsCommon[;{0<count x};""];
checkColPathExist: {[colName] checkPathsCommon[; not in[colName;]@; " ", string[colName], " not"]}
checkColPathNotExist:  {[colName] checkPathsCommon[;colName in; " ",string colName]}

// @brief Build all paths to a table within a database.
// @param db fileSymbol Path to database root.
// @param tname symbol Table name.
// @param dates date[] Optional: list of dates to restrict to.
// @return fileSymbols List of paths to table within database.
buildTablePaths:('[{[p]
    if[not count[p] in 2 3; '"two or three parameters must be passed to buildTablePaths"];
    (db:`s;tname:`s): 2#p;
    if[0=count files:key db; :`$()];
    if[any files like "par.txt"; :raze (.z.s[;tname] hsym@) each `$read0 .Q.dd[db;`par.txt]];
    files@:where files like "[0-9]*";
    files@:where not files like "*$"; / ignore directories ending with $
    if[3=count p; files: files inter `$string p 2];
    (.Q.dd[db;] ,[;tname]@) each files
 };enlist]);

// @brief Convert a file path to a correctly formatted OS string.
// @param path fileSymbol File path to convert.
// @return String Converted file path.
convertPath:{[path:`s]
    path:string path;
    if[isWindows; path[where"/"=path]:"\\"];
    .Q.s1 (":"=first path)_ path
 };

// @brief Copy a source file to a destination file.
// @param src fileSymbol File to copy.
// @param dst fileSymbol Location to copy to.
copy:{[src:`s;dst:`s] system $[isWindows; "xcopy /v /z /E /I "; "cp -r "]," " sv convertPath each src,dst;};


// @brief Get all column names from a splayed table.
// @param tdir fileSymbol Table directory.
// @return symbols Column names (empty if tdir does not exist).
getColNames:{[tdir:`s] $[count key .Q.dd[tdir;`.d]; get tdir,`.d; `$()]};

isWindows:.z.o in`w32`w64;

// @brief Copy a source file to a destination file.
// @param src fileSymbol File to copy.
// @param dst fileSymbol Location to copy to.
rename:{[src:`s;dst:`s] system $[isWindows; "move "; "mv "]," " sv convertPath each src,dst;};

getCompParam:{[path:`s]
    compstat: -21!path;
    $[count compstat; compstat `logicalBlockSize`algorithm`zipLevel; 0 0 0i]
 };

// @param Add a single new table.
// @param tdir fileSymbol New table directory.
// @param db fileSymbol Path to database root.
// @param domain symbol Sym file (domain) name.
// @param data table New table data.
// @param compparam int[]|dict Compression parameter passed to `set`
add1Tab:{[tdir:`s;db:`s;domain:`s;data;compparam]
    (.Q.dd[tdir;`], $[99h ~ type compparam;enlist;] compparam) set .Q.ens[db;data;domain];
 };


// @brief Delete a table directory and its contents.
// @param tdir fileSymbol Table directory to delete.
del1Tab:{[tdir:`s] if[not ()~files:key tdir; (hdel .Q.dd[tdir;]@) each files,`]};


// @brief Rename a table.
// @param old fileSymbol Path to current table within a partition.
// @param new fileSymbol Path to new table within a partition.
rename1Tab:{[old:`s;new:`s] if[()~key new; rename[old;new]]};

// @brief Reorder the columns in a single database table.
// @param tdir fileSymbol Table directory.
// @param order symbols New ordering of the columns.
reorder1Cols:{[tdir:`s;order:`S]
    if[not all exists:order in colNames:get tdir,`.d;
        '"Unknown column(s): ","," sv string order where not exists
    ];
    @[tdir;`.d;:;order,colNames except order];
 };


// @brief Add a column to a splayed table.
// @param tdir fileSymbol Table directory.
// @param cname symbol Column name.
// @param default any Default value of the column.
// @param compparam int[] Compression parameter for the column.
add1Col:{[tdir:`s;cname:`s;default;compparam:`I]
    len:count get tdir,first get tdir,`.d;
    (.Q.dd[tdir;cname], compparam) set len#enlist default;
    @[tdir;`.d;,;cname]
 };

// @brief Delete a column from a database table.
// @param tdir fileSymbol Table directory.
// @param cname symbol Name of column to be deleted.
del1Col:{[tdir:`s;cname:`s]
    hdel .Q.dd[tdir;cname];
    if[(hname:`$string[cname],"#") in key tdir; hdel .Q.dd[tdir;hname]];
    if[(hname:`$string[cname],"##") in key tdir; hdel .Q.dd[tdir;hname]];
    @[tdir;`.d;:;get[tdir,`.d] except cname]
 };

// @brief Rename a column in a single database table.
// @param tdir fileSymbol Table directory.
// @param old symbol Current column name.
// @param new symbol New column name.
rename1Col:{[tdir:`s;old:`s;new:`s]
    if[new in key tdir;
        '"Column ", (string new), " exists in ", 1_string tdir];
    rename . .Q.dd[tdir;] each old,new;
    if[(hname:`$string[old],"#") in key tdir;
        rename . .Q.dd[tdir;] each hname,`$string[new],"#"
    ];
    if[(hname:`$string[old],"##") in key tdir;
        rename . .Q.dd[tdir;] each hname,`$string[new],"##"
    ];
    colNames: get tdir, `.d;
    @[tdir;`.d;:;.[colNames;where colNames=old;:;new]]
 };

// @brief Copy the data from an existing column in a table to a new column.
// @param tdir fileSymbol Table directory.
// @param srcCol symbol Column name whose data will be copied.
// @param dstCol symbol New column name that will be created.
copy1Col:{[tdir:`s;srcCol:`s;dstCol:`s]
    if[dstCol in key tdir;
        '"Column ", (string dstCol), " exists in ", 1_string tdir];
    copy . .Q.dd[tdir;] each srcCol,dstCol;
    if[(hname:`$string[srcCol],"#") in key tdir;
        copy . .Q.dd[tdir;] each hname,`$string[dstCol],"#"
    ];
    if[(hname:`$string[srcCol],"##") in key tdir;
        copy . .Q.dd[tdir;] each hname,`$string[dstCol],"##"
    ];
    @[tdir;`.d;,;dstCol]
 };


// @brief Apply a function to a single database table.
// @param tdir fileSymbol Table directory.
// @param cname symbol Column name.
// @param fn function Unary function to apply to the column.
fn1Col:{[tdir:`s;cname:`s;fn]
    oldAttr:attr oldVal:get tdir,cname;
    newAttr:attr newVal:fn oldVal;
    if[$[oldAttr~newAttr;not oldVal~newVal;1b];
        (.Q.dd[tdir;cname], getCompParam[.Q.dd[tdir;cname]]) set newVal;
    ]
 };


// @brief Verify reorder colums parameters are valid,
// i.e. not the same as current order and all columns exist in the table.
// @param new New ordering of the columns.
// @param current Current column names of the table.
verifyReorderCols:{[new:`S; current:`S]
    if[current ~ new; '"New column order is the same as current order"];
    if[not all exists:new in current;
        '"Unknown column(s): ","," sv string new where not exists];
 };


// @brief Add missing columns to a single database table
// @param tdir fileSymbol Table directory.
// @param goodTdir fileSymbol Path of a table directory which has no missing columns.
add1MissingCols:{[tdir:`s;goodTdir:`s]
    goodCols:getColNames goodTdir;
    if[count missing:goodCols except getColNames tdir;
        {[d;g;c]
            add1Col[d;c;1#0#get g,c;getCompParam[.Q.dd[g;c]]]
        }[tdir;goodTdir;] each missing;
        reorder1Cols[tdir;goodCols]
    ]
 };
