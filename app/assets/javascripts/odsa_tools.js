$(function () {
  var storeName = `odsaAnalyticsBookId_${ODSA_DATA.inst_book_id}`;
  var odsaStore = localforage.createInstance({
    name: storeName,
    storeName: storeName,
  });

  // Returns weeks start and end dates
  function getWeeksDates(start, end) {
    var sDate;
    var eDate;
    var dateArr = [];
    var daysHash = {};
    var daysArr = [];

    while (start <= end) {
      daysHash[getTimestamp(start, "yyyymmdd")] = dateArr.length;
      daysArr.push(getTimestamp(new Date(start.getTime())));
      if (start.getDay() == 1 || (dateArr.length == 0 && !sDate)) {
        sDate = new Date(start.getTime());
      }
      if ((sDate && start.getDay() == 0) || start.getTime() == end.getTime()) {
        eDate = new Date(start.getTime());
      }
      if (sDate && eDate) {
        dateArr.push([sDate, eDate]);
        sDate = undefined;
        eDate = undefined;
      }
      start.setDate(start.getDate() + 1);
    }

    daysHash[getTimestamp(end, "yyyymmdd")] = dateArr.length;
    var lastDate = new Date(dateArr[dateArr.length - 1][1]);
    if (lastDate < end) {
      dateArr.push([new Date(lastDate.setDate(lastDate.getDate() + 1)), end]);
    }
    return { weeksDates: dateArr, daysHash: daysHash, daysArr: daysArr };
  }

  // Compares two arrays and return the difference
  function arrDiff(a1, a2) {
    var a = [],
      diff = [];

    for (var i = 0; i < a1.length; i++) {
      a[a1[i]] = true;
    }

    for (var i = 0; i < a2.length; i++) {
      if (a[a2[i]]) {
        delete a[a2[i]];
      } else {
        a[a2[i]] = true;
      }
    }

    for (var k in a) {
      diff.push(k);
    }

    return diff;
  }

  // Gets lookup data in array or object format form the local storage or the server
  function getLookupData(odsaStore) {
    var currentDate = getTimestamp(new Date(), "yyyymmdd");

    var promise = new Promise((resolve, reject) => {
      getStoreData(odsaStore, "odsaLookupData")
        .then((result) => {
          if (
            result &&
            Object.keys(result).includes("date") &&
            result["date"] == currentDate
          ) {
            resolve(result["data"]);
          } else {
            Plotly.d3.json(
              "/course_offerings/time_tracking_lookup/" +
                ODSA_DATA.course_offering_id,
              function (err, data) {
                if (err) {
                  reject(err);
                }

                var termStartDate = new Date(
                  data["term"][0]["starts_on"] + "T23:59:59-0000"
                );
                var termEndDate = new Date(
                  data["term"][0]["ends_on"] + "T23:59:59-0000"
                );
                var currentDate = new Date();
                if (currentDate <= termStartDate) {
                  reject(
                    `Term starts in a future date ${data["term"][0]["starts_on"]}`
                  );
                  return;
                }
                var trackingEndDate =
                  termEndDate > currentDate ? currentDate : termEndDate;
                let { weeksDates, daysHash, daysArr } = getWeeksDates(
                  termStartDate,
                  termEndDate
                );

                var weeksDatesShort = weeksDates.map(function (x) {
                  var startDate = getTimestamp(x[0]);
                  var endDate = getTimestamp(x[1]);
                  return [startDate, endDate];
                });

                var weeksNames = weeksDates.map(function (x) {
                  var startDate = getTimestamp(x[0]).split("-");
                  var endDate = getTimestamp(x[1]).split("-");
                  var startDateMonth = x[0].toLocaleString("default", {
                    month: "short",
                  });
                  var endDateMonth = x[1].toLocaleString("default", {
                    month: "short",
                  });
                  return (
                    startDateMonth +
                    startDate[2] +
                    "-" +
                    endDateMonth +
                    endDate[2]
                  );
                });

                var weeksEndDates = weeksDatesShort.map(function (x) {
                  return x[1];
                });
                var users = data["users"];
                var usersHash = {};
                var usersEmailHash = {};
                var usersIds = [];
                for (var i = 0; i < users.length; i++) {
                  usersHash[String(users[i]["id"])] = i;
                  usersEmailHash[users[i]["email"]] = i;
                  usersIds.push(users[i]["id"]);
                }

                for (var i = 0; i < users.length; i++) {}

                var chapters = data["chapters"];
                var chaptersNamesIds = [];
                var chaptersNames = [];
                var chaptersIds = [];
                for (var i = 0; i < chapters.length; i++) {
                  var chapterName = chapters[i]["ch_name"];
                  var chapterId = chapters[i]["ch_id"];
                  if (!chaptersNames.includes(chapterName)) {
                    chaptersNamesIds.push({
                      ch_name: chapterName,
                      ch_id: chapterId,
                    });
                    chaptersNames.push(chapterName);
                    chaptersIds.push(chapterId);
                  }
                }

                var chaptersHash = {};
                var chaptersDates = [];
                for (var i = 0; i < chaptersNamesIds.length; i++) {
                  chaptersHash[String(chaptersNamesIds[i]["ch_id"])] = i;
                  chaptersDates.push(daysArr[i]);
                }

                var modulesNames = [];
                var modulesGradable = [];
                var modulesGradableHash = {};
                var modulesIds = [];
                var modulesHash = {};
                var chaptersModulesHash = {};
                var chaptersModulesHash2 = {};
                var modulesNamesHash = {};
                var modulesChaptersHash = {};
                var chapterId = "";
                var modHashIndex = 0;
                var chModHashIndex = 1;
                for (var i = 0; i < chapters.length; i++) {
                  var mod_name = chapters[i]["mod_name"];
                  var mod_id = chapters[i]["mod_id"];
                  var ch_name = chapters[i]["ch_name"];
                  var ch_id = chapters[i]["ch_id"];
                  var ch_mod_id = chapters[i]["ch_mod_id"];
                  var assign_id = chapters[i]["assign_id"] || null;
                  modulesNames.push(mod_name);
                  modulesIds.push(mod_id);
                  if (assign_id) {
                    modulesGradable.push({
                      mod_name: mod_name,
                      mod_id: mod_id,
                      ch_name: ch_name,
                      ch_id: ch_id,
                      ch_mod_id: ch_mod_id,
                    });
                    modulesGradableHash[ch_mod_id] = `${ch_name}-${mod_name}`;
                  }
                  if (ch_id != chapterId) {
                    chModHashIndex = 1;
                    modHashIndex = 0;
                    chapterId = ch_id;
                  } else {
                    chModHashIndex += 1;
                    modHashIndex += 1;
                  }
                  chaptersModulesHash[chapterId] = chModHashIndex;

                  if (
                    !Object.keys(chaptersModulesHash2).includes(String(ch_id))
                  ) {
                    chaptersModulesHash2[ch_id] = [];
                  }
                  chaptersModulesHash2[ch_id].push(mod_id);

                  modulesHash[mod_id] = modHashIndex;
                  modulesNamesHash[mod_id] = mod_name;
                  modulesChaptersHash[mod_id] = ch_id;
                }

                var modulesSectionsHash = {};
                for (var i = 0; i < chaptersIds.length; i++) {
                  var chapterId = chaptersIds[i];
                  modulesSectionsHash[chapterId] = {};
                  var _modulesIds = chaptersModulesHash2[chapterId];
                  for (var j = 0; j < _modulesIds.length; j++) {
                    var moduleId = _modulesIds[j];
                    modulesSectionsHash[chapterId][moduleId] = [];
                  }
                }

                var usersIdsDiff = [];
                if (result["data"]) {
                  var prevUsersIds = result["data"]["usersIds"];
                  if (prevUsersIds.length != usersIds.length) {
                    usersIdsDiff = arrDiff(prevUsersIds, usersIds);
                  }
                }

                var odsaLookupData = {
                  chapters: data["chapters"],
                  chaptersDates: chaptersDates,
                  chaptersHash: chaptersHash,
                  chaptersIds: chaptersIds,
                  chaptersNames: chaptersNames,
                  chaptersNamesIds: chaptersNamesIds,
                  daysHash: daysHash,
                  daysArr: daysArr,
                  daysIds: Object.keys(daysHash),
                  term: data["term"][0],
                  trackingEndDate: getTimestamp(trackingEndDate, "yyyymmdd"),
                  users: data["users"],
                  usersHash: usersHash,
                  usersEmailHash: usersEmailHash,
                  usersIds: usersIds,
                  usersIdsDiff: usersIdsDiff,
                  weeksDates: weeksDatesShort,
                  weeksEndDates: weeksEndDates,
                  weeksNames: weeksNames,
                  modulesNames: modulesNames, // Array of mod names
                  modulesGradable: modulesGradable,
                  modulesGradableHash: modulesGradableHash,
                  modulesIds: modulesIds, // Array of mod_ids
                  modulesHash: modulesHash, // maps mod_id to the order of the module in the chapter
                  chaptersModulesHash: chaptersModulesHash, // maps ch_id to number of modules in the chapter
                  chaptersModulesHash2: chaptersModulesHash2, //maps ch_id to array of mod_ids in the chapter
                  modulesSectionsHash: modulesSectionsHash, // maps ch_id to modulesSections hash
                  modulesNamesHash: modulesNamesHash, // maps mod_id to mod_name
                  modulesChaptersHash: modulesChaptersHash, // maps mod_id to ch_id
                };

                updateStoreData(odsaStore, "odsaLookupData", odsaLookupData);
                resolve(odsaLookupData);
              }
            );
          }
        })
        .catch((err) => {
          reject(err);
        });
    });

    return promise;
  }

  // Fetches data form the local store
  function getStoreData(odsaStore, dataPrefix) {
    // Get the most recent store data
    var dataPrefix = dataPrefix || "";
    var _keys = [];

    var promise = new Promise((resolve, reject) => {
      odsaStore
        .keys()
        .then(function (keys) {
          keys.forEach(function (key, i) {
            if (key.startsWith(dataPrefix)) {
              var keyDate = key.split("-")[1];
              _keys.push(parseInt(keyDate));
            }
          });

          if (!_keys.length) {
            resolve({ data: null, date: null });
          }
          // sort in descending order
          _keys.sort(function (a, b) {
            return a - b;
          });

          // get the most recent record
          odsaStore
            .getItem([dataPrefix, _keys[0]].join("-"))
            .then(function (data) {
              resolve({ data: data, date: String(_keys[0]) });
            })
            .catch(function (err) {
              reject(err);
            });
        })
        .catch(function (err) {
          reject(err);
        });
    });

    return promise;
  }

  // Insert data in the local storage prefixed with the current date and remove all other data form previous days
  function updateStoreData(odsaStore, dataPrefix, data) {
    // deletes all the store data except the current date
    var currentDate = getTimestamp(new Date(), "yyyymmdd");
    var dataPrefix = dataPrefix || "";
    var _keys = [];
    var promise = new Promise((resolve, reject) => {
      odsaStore
        .keys()
        .then(function (keys) {
          keys.forEach(function (key, i) {
            if (key.startsWith(dataPrefix)) {
              var keyDate = key.split("-")[1];
              if (parseInt(keyDate) != parseInt(currentDate)) {
                _keys.push(key);
              }
            }
          });
          var promises = _keys.map(function (item) {
            return odsaStore.removeItem(item);
          });
          Promise.all(promises).then((sessions) => {
            odsaStore.setItem([dataPrefix, currentDate].join("-"), data);
            resolve(sessions);
          });
        })
        .catch(function (err) {
          console.log("Error updating store data " + dataPrefix + ": " + err);
          reject(err);
        });
    });
    return promise;
  }

  // Delete data from the local storage
  function deleteStoreData(odsaStore, dataPrefix) {
    var dataPrefix = dataPrefix || "";
    var _keys = [];
    var promise = new Promise((resolve, reject) => {
      odsaStore
        .keys()
        .then(function (keys) {
          keys.forEach(function (key, i) {
            if (key.startsWith(dataPrefix)) {
              _keys.push(key);
            }
          });
          var promises = _keys.map(function (item) {
            return odsaStore.removeItem(item);
          });
          Promise.all(promises).then((sessions) => {
            resolve(sessions);
          });
        })
        .catch(function (err) {
          console.log("Error deleting store data " + dataPrefix + ": " + err);
          reject(err);
        });
    });
    return promise;
  }

  // Gets visualizations data form the local storage if found. Otherwise get it from the server
  function getTimeTrackingData(odsaStore, lookups, count) {
    var currentDate = getTimestamp(new Date(), "yyyymmdd");
    var trackingEndDate = lookups["trackingEndDate"];

    var promise = new Promise((resolve, reject) => {
      getStoreData(odsaStore, "odsaTimeTrackingData")
        .then((result) => {
          if (
            result &&
            Object.keys(result).includes("date") &&
            result["date"] == currentDate
          ) {
            resolve(result["data"]);
          } else {
            // else recursively fetch all the days until today and
            var date = result["date"]
              ? addDay(result["date"])
              : lookups["term"]["starts_on"].replace(/-/g, "");

            // show the overlay
            $.LoadingOverlay("show", {
              text: "Downloading OpenDSA Analytics Data",
              textResizeFactor: 0.3,
              progress: true,
            });

            var progressEnd = parseInt(trackingEndDate) - parseInt(date);
            _getTimeTrackingData(
              odsaStore,
              "/course_offerings/time_tracking_data/" +
                ODSA_DATA.course_offering_id +
                "/date/",
              date,
              result["data"],
              lookups,
              progressEnd,
              count
            )
              .then((odsaTimeTrackingData) => {
                resolve(odsaTimeTrackingData);
              })
              .catch((err) => {
                reject(err);
              });
          }
        })
        .catch((err) => {
          reject(err);
        });
    });
    return promise;
  }

  // Adds one day to the given date and returns a new date
  function addDay(date) {
    //TODO: refactor
    var date = [
      date.substring(0, 4),
      date.substring(4, 6),
      date.substring(6, 8),
    ].join("-");
    date = date ? new Date(date + "T23:59:59-0000") : new Date();
    return getTimestamp(new Date(date.setDate(date.getDate() + 1)), "yyyymmdd");
  }

  // Adds a delay in ms
  function sleeper(ms) {
    return function (x) {
      return new Promise((resolve) => setTimeout(() => resolve(x), ms));
    };
  }

  // Gets time tracking data form the server for one day
  const _getTimeTrackingDataPerDay = async function (url, date, backoff) {
    var data = await fetch(url + date)
      .then(sleeper(backoff))
      .then((res) => res.json());
    return data;
  };

  // Gets time tracking data recursively form the server
  const _getTimeTrackingData = async function (
    odsaStore,
    url,
    date,
    storeData,
    lookups,
    progressEnd,
    count
  ) {
    var backoff = 1000 * count;
    var storeData = storeData || null;
    var trackingEndDate = lookups["trackingEndDate"];
    var progress =
      100 - ((parseInt(trackingEndDate) - parseInt(date)) * 100) / progressEnd;
    var progressPercent = progress.toFixed(2);

    if (parseInt(date) <= parseInt(trackingEndDate)) {
      var text = `${progressPercent}% Downloading OpenDSA Analytics Data.`;
      $.LoadingOverlay("progress", progress);
      $.LoadingOverlay("text", text);
      var data = await _getTimeTrackingDataPerDay(url, date, backoff);
      storeData = formatTimeTrackingData(storeData, data, lookups);
      return await _getTimeTrackingData(
        odsaStore,
        url,
        addDay(date),
        storeData,
        lookups,
        progressEnd,
        count
      );
    } else {
      storeData = enrichStoreData(storeData);
      updateStoreData(odsaStore, "odsaTimeTrackingData", storeData);
      $.LoadingOverlay("hide");
      return storeData;
    }
  };

  // Calculates q1, median, and q3 for array of numbers
  function stats(arr) {
    var sortedArr = [...arr].sort(Plotly.d3.ascending);
    var q1 = Plotly.d3.quantile(sortedArr, 0.25);
    var median = Plotly.d3.quantile(sortedArr, 0.5);
    var q3 = Plotly.d3.quantile(sortedArr, 0.75);

    return {
      q1: q1,
      median: median,
      q3: q3,
    };
  }

  // Calculates q1, median, and q3 for visualizations data
  function enrichStoreData(storeData) {
    var weeksData =
      storeData && Object.keys(storeData).includes("weeksData")
        ? storeData["weeksData"]
        : [];
    var chaptersData =
      storeData && Object.keys(storeData).includes("chaptersData")
        ? storeData["chaptersData"]
        : [];

    var weeksStats = weeksData.map(function (row) {
      return stats(row);
    });
    var weeksQ1 = weeksStats.map(function (row) {
      return row["q1"];
    });
    var weeksMedian = weeksStats.map(function (row) {
      return row["median"];
    });
    var weeksQ3 = weeksStats.map(function (row) {
      return row["q3"];
    });

    var chaptersStats = chaptersData.map(function (row) {
      return stats(row);
    });
    var chaptersQ1 = chaptersStats.map(function (row) {
      return row["q1"];
    });
    var chaptersMedian = chaptersStats.map(function (row) {
      return row["median"];
    });
    var chaptersQ3 = chaptersStats.map(function (row) {
      return row["q3"];
    });

    var weeksTranspose = weeksData.length ? transpose(weeksData) : [];
    var chaptersTranspose = chaptersData.length ? transpose(chaptersData) : [];

    storeData["weeksStats"] = weeksStats;
    storeData["weeksQ1"] = weeksQ1;
    storeData["weeksMedian"] = weeksMedian;
    storeData["weeksQ3"] = weeksQ3;
    storeData["chaptersStats"] = chaptersStats;
    storeData["chaptersQ1"] = chaptersQ1;
    storeData["chaptersMedian"] = chaptersMedian;
    storeData["chaptersQ3"] = chaptersQ3;
    storeData["weeksTranspose"] = weeksTranspose;
    storeData["chaptersTranspose"] = chaptersTranspose;
    return storeData;
  }

  // UUID generator
  function uuidv4() {
    return ([1e7] + -1e3 + -4e3 + -8e3 + -1e11).replace(/[018]/g, (c) =>
      (
        c ^
        (crypto.getRandomValues(new Uint8Array(1))[0] & (15 >> (c / 4)))
      ).toString(16)
    );
  }

  // Generates random data for testing
  function generateRandomData(odsaStore, format) {
    var currentDate = getTimestamp(new Date(), "yyyymmdd");
    var format = format || "csv";
    var insertStmt = "INSERT INTO opendsa.odsa_user_time_trackings VALUES";
    var promise = new Promise((resolve, reject) => {
      getLookupData(odsaStore)
        .then((lookups) => {
          var statement = "";
          var csvFile = "";
          var csvRecord = "";
          var daysArr = lookups["daysArr"];
          var users = lookups["users"];
          var chapters = lookups["chapters"];
          var openBrace = "(";
          var sectionsTime = "'NotNull'";
          var closeBrace = ")";
          var comma = ",";
          var simiColon = ";";
          var nullStr = "NULL";
          var emptyStr = "";
          var newLine = "\n";

          // for every user
          for (var i = 0; i < users.length; i++) {
            // for every chapter
            for (var j = 0; j < chapters.length; j++) {
              // for every week
              for (var k = 0; k < daysArr.length; k++) {
                var userId = users[i]["id"];
                var instBookId = ODSA_DATA.inst_book_id;
                var instModuleId = chapters[j]["mod_id"];
                var instChapterId = chapters[j]["ch_id"];
                var UUID = uuidv4();
                var sessionDate = daysArr[k].replace(/-/g, "");
                var totalTime = parseFloat(
                  (Math.random() * (i + 1) * 7).toFixed(2)
                );
                if (format == "csv") {
                  csvRecord =
                    userId +
                    comma +
                    instBookId +
                    comma +
                    instModuleId +
                    comma +
                    instChapterId +
                    comma +
                    UUID +
                    comma +
                    sessionDate +
                    comma +
                    totalTime +
                    comma +
                    sectionsTime +
                    newLine;

                  csvFile += csvRecord;
                } else {
                  statement =
                    openBrace +
                    nullStr +
                    comma +
                    userId +
                    comma +
                    instBookId +
                    comma +
                    nullStr +
                    comma +
                    nullStr +
                    comma +
                    nullStr +
                    comma +
                    instModuleId +
                    comma +
                    instChapterId +
                    comma +
                    nullStr +
                    comma +
                    nullStr +
                    comma +
                    `'${UUID}'` +
                    comma +
                    `'${sessionDate}'` +
                    comma +
                    totalTime +
                    comma +
                    sectionsTime +
                    comma +
                    nullStr +
                    comma +
                    nullStr +
                    closeBrace +
                    comma;

                  insertStmt += statement;
                }
              }
            }
            if (format != "csv") {
              insertStmt = insertStmt.replace(/.$/, simiColon);
              insertStmt +=
                "INSERT INTO opendsa.odsa_user_time_trackings VALUES";
            }
          }
          resolve({
            data: format == "csv" ? csvFile : insertStmt,
            date: currentDate,
          });
        })
        .catch((err) => {
          reject(err);
        });
    });

    return promise;
  }

  // Transforms and aggregate raw data coming from the server into visualizations data format
  function formatTimeTrackingData(storeData, data, lookups) {
    // TODO: validate input data object
    var weeksData =
      storeData && Object.keys(storeData).includes("weeksData")
        ? storeData["weeksData"]
        : [];
    var chaptersData =
      storeData && Object.keys(storeData).includes("chaptersData")
        ? storeData["chaptersData"]
        : [];
    var chaptersTotalData =
      storeData && Object.keys(storeData).includes("chaptersTotalData")
        ? storeData["chaptersTotalData"]
        : [];
    var modulesData =
      storeData && Object.keys(storeData).includes("modulesData")
        ? storeData["modulesData"]
        : {};
    var modulesTotalData =
      storeData && Object.keys(storeData).includes("modulesTotalData")
        ? storeData["modulesTotalData"]
        : {};
    var modulesSectionsHash = lookups["modulesSectionsHash"];
    var sectionsLookup =
      storeData && Object.keys(storeData).includes("sectionsLookup")
        ? storeData["sectionsLookup"]
        : JSON.parse(JSON.stringify(modulesSectionsHash));
    var sectionsData =
      storeData && Object.keys(storeData).includes("sectionsData")
        ? storeData["sectionsData"]
        : JSON.parse(JSON.stringify(modulesSectionsHash));
    var sectionsTotalData =
      storeData && Object.keys(storeData).includes("sectionsTotalData")
        ? storeData["sectionsTotalData"]
        : JSON.parse(JSON.stringify(modulesSectionsHash));
    var weeksDates = lookups["weeksDates"];
    var daysHash = lookups["daysHash"];
    var daysIds = lookups["daysIds"];
    var chaptersHash = lookups["chaptersHash"];
    var chaptersIds = lookups["chaptersIds"];
    var chaptersModulesHash = lookups["chaptersModulesHash"];
    var modulesIds = lookups["modulesIds"];
    var modulesHash = lookups["modulesHash"];
    var usersHash = lookups["usersHash"];
    var usersIds = lookups["usersIds"];
    var usersIdsDiff = lookups["usersIdsDiff"];
    var users = lookups["users"];

    function addRow(matrix, length) {
      var clone = JSON.parse(JSON.stringify(matrix));
      var length = length || clone[0].length;
      var zeroRow = new Array(length);
      for (let i = 0; i < length; ++i) zeroRow[i] = 0;
      clone.push(zeroRow);
      return clone;
    }

    function addCol(matrix) {
      if (matrix) {
        for (var i = 0; i < matrix.length; i++) {
          if (matrix[i]) {
            matrix[i].push(0);
          }
        }
      }
      return matrix;
    }

    // init weeksData matrix
    if (weeksData.length == 0) {
      for (var i = 0; i < weeksDates.length; i++) {
        weeksData = addRow(weeksData, users.length);
      }
    }

    // init chaptersData matrix
    if (chaptersData.length == 0) {
      for (var i = 0; i < chaptersIds.length; i++) {
        chaptersData = addRow(chaptersData, users.length);
      }
    }

    // init chaptersTotalData array
    if (chaptersTotalData.length == 0) {
      for (var i = 0; i < chaptersIds.length; i++) {
        chaptersTotalData.push(0);
      }
    }

    // init modulesData object
    if ($.isEmptyObject(modulesData)) {
      for (var i = 0; i < chaptersIds.length; i++) {
        var chapterId = chaptersIds[i];
        modulesData[chapterId] = [];
        for (var j = 0; j < chaptersModulesHash[chapterId]; j++) {
          modulesData[chapterId] = addRow(modulesData[chapterId], users.length);
        }
      }
    }

    // init modulesTotalData object
    if ($.isEmptyObject(modulesTotalData)) {
      for (var i = 0; i < chaptersIds.length; i++) {
        var chapterId = chaptersIds[i];
        modulesTotalData[chapterId] = [];
        for (var j = 0; j < chaptersModulesHash[chapterId]; j++) {
          modulesTotalData[chapterId].push(0);
        }
      }
    }

    // TODO: add columns to modulesData and modulesTotalData
    for (var i = 0; i < usersIdsDiff.length; i++) {
      weeksData = addCol(weeksData);
      chaptersData = addCol(chaptersData);
    }

    // add data to weeks and chapters matrices
    for (var i = 0; i < data.length; i++) {
      var dt = data[i]["dt"];
      var usr_id = data[i]["usr_id"];
      var ch_id = data[i]["ch_id"];
      var mod_id = data[i]["mod_id"];
      var st = data[i]["st"];
      var tt = Math.round((data[i]["tt"] * 100.0) / 60) / 100;

      if (usersIds.includes(usr_id)) {
        // Aggregate weeksData
        if (daysIds.includes(dt)) {
          weeksData[daysHash[dt]][usersHash[usr_id]] += tt;
        }

        // Aggregate chaptersData/chaptersTotalData
        if (chaptersIds.includes(ch_id)) {
          chaptersData[chaptersHash[ch_id]][usersHash[usr_id]] += tt;
          chaptersTotalData[chaptersHash[ch_id]] += tt;

          // Aggregate modulesData/modulesTotalData
          if (modulesIds.includes(mod_id)) {
            modulesData[String(ch_id)][modulesHash[mod_id]][
              usersHash[usr_id]
            ] += tt;
            modulesTotalData[String(ch_id)][modulesHash[mod_id]] += tt;

            try {
              st = JSON.parse(st);
              if (Array.isArray(st)) {
                // init sectionsLookup hash
                if (sectionsLookup[ch_id][mod_id].length == 0) {
                  for (var j = 0; j < st.length; j++) {
                    var sectionName = Object.keys(st[j])[0];
                    if (!sectionsLookup[ch_id][mod_id].includes(sectionName)) {
                      sectionsLookup[ch_id][mod_id].push(sectionName);
                    }
                  }
                }

                // init sectionsData matrices
                if (sectionsData[ch_id][mod_id].length == 0) {
                  var sectionsArr = sectionsLookup[ch_id][mod_id];
                  for (var l = 0; l < sectionsArr.length; l++) {
                    sectionsData[ch_id][mod_id] = addRow(
                      sectionsData[ch_id][mod_id],
                      users.length
                    );
                  }
                }

                // init sectionsTotalData matrices
                if (sectionsTotalData[ch_id][mod_id].length == 0) {
                  var sectionsArr = sectionsLookup[ch_id][mod_id];
                  for (var l = 0; l < sectionsArr.length; l++) {
                    sectionsTotalData[ch_id][mod_id].push(0);
                  }
                }

                // Aggregate sectionsData and sectionsTotalData
                for (var k = 0; k < st.length; k++) {
                  var sectionName = Object.keys(st[k])[0];
                  var sectionTime =
                    Math.round((Object.values(st[k])[0] * 100.0) / 60) / 100;
                  var index =
                    sectionsLookup[ch_id][mod_id].indexOf(sectionName);

                  sectionsData[ch_id][mod_id][index][usersHash[usr_id]] +=
                    sectionTime;
                  sectionsTotalData[ch_id][mod_id][index] += sectionTime;
                }
              }
            } catch (e) {
              // console.log(e)
            }
          }
        }
      }
    }

    return {
      weeksData: weeksData,
      chaptersData: chaptersData,
      chaptersTotalData: chaptersTotalData,
      modulesData: modulesData,
      modulesTotalData: modulesTotalData,
      sectionsLookup: sectionsLookup,
      sectionsData: sectionsData,
      sectionsTotalData: sectionsTotalData,
    };
  }

  // Returns a matrix transpose
  function transpose(m) {
    return m[0].map((x, i) => m.map((x) => x[i]));
  }

  var REGEX_EMAIL =
    "([a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@" +
    "(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)";

  function formatName(item) {
    return $.trim((item.first_name || "") + " " + (item.last_name || ""));
  }

  // Initializes Plotly Box plot
  function initBoxPlot(vizData, lookups) {
    var chaptersData = vizData["chaptersData"];
    var chaptersNames = lookups["chaptersNames"];
    var users = lookups["users"];
    var usersEmailHash = lookups["usersEmailHash"];
    var weeksData = vizData["weeksData"];
    var weeksNames = lookups["weeksNames"];
    var numOfWeeks = weeksData.length;
    var text = users.map(
      (x) => x.first_name + " " + x.last_name + "<" + x.email + ">"
    );
    var dataTables = null;
    var currentBoxTab = "weeks";

    function createDataTables(chosenStudentsInfo, caption) {
      var caption = caption || "";

      if ($(".students_caption").length) {
        $(".students_caption").text(caption);
      } else {
        $("#students_info").append(
          '<caption style="caption-side: top" class="students_caption">' +
            caption +
            "</caption>"
        );
      }

      return $("#students_info").DataTable({
        destroy: true,
        data: chosenStudentsInfo,
        columns: [
          { title: "Fist Name" },
          { title: "Last Name" },
          { title: "Email" },
          { title: "Reading time" },
        ],
      });
    }

    function clearDataTables(dataTables) {
      if ($(".students_caption").length) {
        $(".students_caption").text("");
      }

      dataTables.rows().remove().draw();
    }

    // plotly data
    var plotlyBoxData = [];
    var weeksVisible = [];
    var chaptersVisible = [];
    // Add weeks
    for (var i = 0; i < weeksData.length; i++) {
      var result = {
        name: weeksNames[i],
        width: 0.5,
        quartilemethod: "inclusive",
        type: "box",
        y: weeksData[i],
        text: text,
        hoverinfo: "all",
        hovertemplate: "%{text}<br>%{y:.2f} mins<extra></extra>",
        boxpoints: "all",
        boxmean: "sd",
        jitter: 0.2,
        whiskerwidth: 0.2,
        fillcolor: "cls",
        marker: {
          outliercolor: "rgb(255, 0, 0)",
          size: 3,
          symbol: "0",
          opacity: 1,
        },
        selectedpoints: [],
        selected: {
          marker: {
            size: 7,
            color: "rgb(255, 0, 0)",
          },
        },
        line: {
          width: 1,
        },
        hoverlabel: {
          font: { size: 15 },
        },
      };
      plotlyBoxData.push(result);
      weeksVisible.push(true);
      chaptersVisible.push(false);
    }

    // Add chapters
    for (var i = 0; i < chaptersData.length; i++) {
      var result = {
        name: chaptersNames[i],
        width: 0.5,
        quartilemethod: "inclusive",
        type: "box",
        y: chaptersData[i],
        text: text,
        hoverinfo: "all",
        hovertemplate: "%{text}<br>%{y:.2f} mins<extra></extra>",
        boxpoints: "all",
        boxmean: "sd",
        jitter: 0.2,
        whiskerwidth: 0.2,
        fillcolor: "cls",
        marker: {
          outliercolor: "rgb(255, 0, 0)",
          size: 3,
          symbol: "0",
          opacity: 1,
        },
        selectedpoints: [],
        selected: {
          marker: {
            size: 7,
            color: "rgb(255, 0, 0)",
          },
        },
        line: {
          width: 1,
        },
        hoverlabel: {
          font: { size: 15 },
        },
        visible: false,
      };
      plotlyBoxData.push(result);
      weeksVisible.push(false);
      chaptersVisible.push(true);
    }

    // plotly menu
    var updatemenus = [
      {
        buttons: [
          {
            name: "weeks",
            args: [
              { visible: weeksVisible },
              {
                title:
                  "Total time students spend on OpenDSA materials per week.",
              },
            ],
            label: "Weeks",
            method: "update",
          },
          {
            name: "chapters",
            args: [
              { visible: chaptersVisible },
              {
                title:
                  "Total time students spend on OpenDSA materials per chapter.",
              },
            ],
            label: "Chapters",
            method: "update",
          },
        ],
        direction: "left",
        pad: { r: 10, t: 10 },
        showactive: true,
        type: "buttons",
        x: 1,
        xanchor: "right",
        y: 1.2,
        yanchor: "top",
      },
      {
        buttons: [
          {
            name: "reset",
            label: "Reset",
            method: "skip",
            execute: false,
          },
          {
            name: "25",
            label: "25th percentile",
            method: "skip",
            execute: false,
          },
          {
            name: "50",
            label: "50th percentile",
            method: "skip",
            execute: false,
          },
        ],
        direction: "left",
        pad: { r: 10, t: 10 },
        showactive: false,
        type: "buttons",
        x: 0,
        xanchor: "left",
        y: 1.2,
        yanchor: "top",
      },
    ];

    // plotly layout
    var plotlyBoxLayout = {
      title: "Total time students spend on OpenDSA materials per week.",
      updatemenus: updatemenus,
      yaxis: {
        title: "Reading time in mins.",
        autorange: true,
        showgrid: true,
        zeroline: true,
        gridcolor: "rgb(255, 255, 255)",
        gridwidth: 1,
        zerolinecolor: "rgb(255, 255, 255)",
        zerolinewidth: 2,
      },
      margin: {
        l: 40,
        r: 30,
        b: 80,
        t: 100,
      },
      paper_bgcolor: "rgb(243, 243, 243)",
      plot_bgcolor: "rgb(243, 243, 243)",
      showlegend: true,
      legend: {
        x: 1.07,
        xanchor: "right",
        y: 1,
      },
    };

    // get the index(es) of the active trace(s)
    function getActiveTraces() {
      var calcdata = plotlyBoxDiv.calcdata;
      var activeTraces = [];
      for (var i = 0; i < calcdata.length; i++) {
        if (calcdata[i][0]["x"] != undefined) activeTraces.push(i);
      }
      return activeTraces;
    }

    function updateBoxPlot(chosenStudents) {
      var chosenStudents = chosenStudents || [];
      var traceIndex = getActiveTraces();

      for (var i = 0; i < traceIndex.length; i++) {
        plotlyBoxData[traceIndex[i]]["selectedpoints"] = chosenStudents;
      }
      Plotly.update(plotlyBoxDiv, plotlyBoxData, plotlyBoxLayout);
    }

    //
    // selectize code
    // initialize selectize for box plot
    $selectize = $("#select-for-box").selectize({
      plugins: ["remove_button"],
      persist: false,
      maxItems: null,
      valueField: "email",
      labelField: "name",
      searchField: ["first_name", "last_name", "email"],
      sortField: [
        { field: "first_name", direction: "asc" },
        { field: "last_name", direction: "asc" },
      ],
      options: users,
      render: {
        item: function (item, escape) {
          var name = formatName(item);
          return (
            "<div>" +
            (name ? '<span class="name">' + escape(name) + "</span>" : "") +
            (item.email
              ? '<span class="email">' + escape(item.email) + "</span>"
              : "") +
            "</div>"
          );
        },
        option: function (item, escape) {
          var name = formatName(item);
          var label = name || item.email;
          var caption = name ? item.email : null;
          return (
            "<div>" +
            '<span class="label">' +
            escape(label) +
            "</span>" +
            (caption
              ? '<span class="caption">' + escape(caption) + "</span>"
              : "") +
            "</div>"
          );
        },
      },
      createFilter: function (input) {
        var regexpA = new RegExp("^" + REGEX_EMAIL + "$", "i");
        var regexpB = new RegExp("^([^<]*)<" + REGEX_EMAIL + ">$", "i");
        return regexpA.test(input) || regexpB.test(input);
      },
      create: function (input) {
        if (new RegExp("^" + REGEX_EMAIL + "$", "i").test(input)) {
          return { email: input };
        }
        var match = input.match(
          new RegExp("^([^<]*)<" + REGEX_EMAIL + ">$", "i")
        );
        if (match) {
          var name = $.trim(match[1]);
          var pos_space = name.indexOf(" ");
          var first_name = name.substring(0, pos_space);
          var last_name = name.substring(pos_space + 1);

          return {
            email: match[2],
            first_name: first_name,
            last_name: last_name,
          };
        }
        return false;
      },
    });

    var selectize = $selectize[0].selectize;

    // show current values in multi input dropdown
    $("select#select-for-box.selectized").each(function () {
      var update = function (e) {
        var selectedStudents = $(this).val();
        if (selectedStudents) {
          var chosenStudents = [];
          for (var i = 0; i < selectedStudents.length; i++) {
            chosenStudents.push(usersEmailHash[selectedStudents[i]]);
          }
          updateBoxPlot(chosenStudents);
          if (dataTables) {
            clearDataTables(dataTables);
          }
        }
      };

      $(this).on("change", update);
    });

    // plotly initialize
    var plotlyBoxDiv = $("#plotlyBoxDiv")[0];
    var promise = new Promise((resolve, reject) => {
      Plotly.newPlot(plotlyBoxDiv, plotlyBoxData, plotlyBoxLayout).then(() => {
        resolve();
      });
    });

    // event handler to select points and show dataTables
    plotlyBoxDiv.on("plotly_buttonclicked", function (e) {
      var buttonName = e.button.name;
      var plotMean = null;
      var plotQ1 = null;
      var traceIndex = null;
      var chosenStudents = [];
      var chosenStudentsInfo = [];
      var studentInfo = {};
      selectize.clear();

      if (["weeks", "chapters"].includes(buttonName)) {
        currentBoxTab = buttonName;
        if (dataTables) {
          clearDataTables(dataTables);
        }
      } else {
        traceIndex = getActiveTraces()[0];

        plotMean = plotlyBoxDiv.calcdata[traceIndex][0]["med"];
        plotQ1 = plotlyBoxDiv.calcdata[traceIndex][0]["q1"];

        var tabIndex =
          traceIndex + 1 > numOfWeeks ? traceIndex - numOfWeeks : traceIndex;
        var refData =
          vizData[currentBoxTab == "weeks" ? "weeksData" : "chaptersData"][
            tabIndex
          ];
        var refName =
          currentBoxTab == "weeks"
            ? weeksNames[tabIndex]
            : chaptersNames[tabIndex];
        if (buttonName == "25") {
          for (var i = 0; i < refData.length; i++) {
            if (refData[i] <= plotQ1) {
              chosenStudents.push(i);
              studentInfo = users[i];
              chosenStudentsInfo.push([
                studentInfo["first_name"],
                studentInfo["last_name"],
                studentInfo["email"],
                refData[i],
              ]);
            }
          }
          dataTables = createDataTables(
            chosenStudentsInfo,
            "Students reading time less than 25th percentile for " + refName
          );
        } else if (buttonName == "50") {
          for (var i = 0; i < refData.length; i++) {
            if (refData[i] <= plotMean) {
              chosenStudents.push(i);
              studentInfo = users[i];
              chosenStudentsInfo.push([
                studentInfo["first_name"],
                studentInfo["last_name"],
                studentInfo["email"],
                refData[i],
              ]);
            }
          }
          dataTables = createDataTables(
            chosenStudentsInfo,
            "Students reading time less than 50th percentile for " + refName
          );
        } else {
          chosenStudents = [];
          if (dataTables) {
            clearDataTables(dataTables);
          }
        }

        plotlyBoxData[traceIndex]["selectedpoints"] = chosenStudents;
        Plotly.update(plotlyBoxDiv, plotlyBoxData, plotlyBoxLayout);
      }
    });
    return promise;
  }

  // Initializes Plotly Time Series plot
  function initLinePlot(vizData, lookups) {
    var chaptersData = vizData["chaptersData"];
    var chaptersMedian = vizData["chaptersMedian"];
    var chaptersQ1 = vizData["chaptersQ1"];
    var chaptersQ3 = vizData["chaptersQ3"];
    var chaptersStats = vizData["chaptersStats"];
    var chaptersDates = lookups["chaptersDates"];
    var chaptersTranspose = vizData["chaptersTranspose"];
    var users = lookups["users"];
    var usersEmailHash = lookups["usersEmailHash"];
    var weeksData = vizData["weeksData"];
    var weeksMedian = vizData["weeksMedian"];
    var weeksQ1 = vizData["weeksQ1"];
    var weeksQ3 = vizData["weeksQ3"];
    var weeksStats = vizData["weeksStats"];
    var weeksTranspose = vizData["weeksTranspose"];
    var weeksDates = lookups["weeksEndDates"];
    var currentLineTab = "weeks";

    //
    // selectize code
    // initialize selectize for box plot
    var $selectize_line = $("#select-for-line").selectize({
      plugins: ["remove_button"],
      persist: false,
      maxItems: null,
      valueField: "email",
      labelField: "name",
      searchField: ["first_name", "last_name", "email"],
      sortField: [
        { field: "first_name", direction: "asc" },
        { field: "last_name", direction: "asc" },
      ],
      options: users,
      render: {
        item: function (item, escape) {
          var name = formatName(item);
          return (
            "<div>" +
            (name ? '<span class="name">' + escape(name) + "</span>" : "") +
            (item.email
              ? '<span class="email">' + escape(item.email) + "</span>"
              : "") +
            "</div>"
          );
        },
        option: function (item, escape) {
          var name = formatName(item);
          var label = name || item.email;
          var caption = name ? item.email : null;
          return (
            "<div>" +
            '<span class="label">' +
            escape(label) +
            "</span>" +
            (caption
              ? '<span class="caption">' + escape(caption) + "</span>"
              : "") +
            "</div>"
          );
        },
      },
      createFilter: function (input) {
        var regexpA = new RegExp("^" + REGEX_EMAIL + "$", "i");
        var regexpB = new RegExp("^([^<]*)<" + REGEX_EMAIL + ">$", "i");
        return regexpA.test(input) || regexpB.test(input);
      },
      create: function (input) {
        if (new RegExp("^" + REGEX_EMAIL + "$", "i").test(input)) {
          return { email: input };
        }
        var match = input.match(
          new RegExp("^([^<]*)<" + REGEX_EMAIL + ">$", "i")
        );
        if (match) {
          var name = $.trim(match[1]);
          var pos_space = name.indexOf(" ");
          var first_name = name.substring(0, pos_space);
          var last_name = name.substring(pos_space + 1);

          return {
            email: match[2],
            first_name: first_name,
            last_name: last_name,
          };
        }
        return false;
      },
    });

    var selectize_line = $selectize_line[0].selectize;

    // show current values in multi input dropdown
    $("select#select-for-line.selectized").each(function () {
      var update = function (e) {
        var selectedStudents = $(this).val();
        if (selectedStudents) {
          var chosenStudents = [];
          for (var i = 0; i < selectedStudents.length; i++) {
            chosenStudents.push(usersEmailHash[selectedStudents[i]]);
          }
          updateLinePlot(chosenStudents);
        }
      };
      $(this).on("change", update);
    });

    function updateLinePlot(chosenStudents) {
      var chosenStudents = chosenStudents || [];
      var plotlyLineData = [];

      for (var i = 0; i < chosenStudents.length; i++) {
        var studentInfo = users[chosenStudents[i]];
        var result = {
          type: "scatter",
          mode: "lines",
          name: studentInfo["first_name"] + " " + studentInfo["last_name"],
          x: currentLineTab === "weeks" ? weeksDates : chaptersDates,
          y:
            currentLineTab === "weeks"
              ? weeksTranspose[chosenStudents[i]]
              : chaptersTranspose[chosenStudents[i]],
          line: {
            dash: "solid",
            width: 1,
          },
        };
        plotlyLineData.push(result);
      }

      addClassStats(plotlyLineData, currentLineTab);

      var range =
        currentLineTab === "weeks"
          ? [weeksDates[0], weeksDates[weeksDates.length - 1]]
          : [chaptersDates[0], chaptersDates[chaptersDates.length - 1]];
      plotlyLineLayout.xaxis.range = range;
      plotlyLineLayout.xaxis.rangeslider.range = range;
      plotlyLineLayout.sliders[0].steps = calculateSteps(
        "median",
        currentLineTab
      );

      Plotly.react(plotlyLineDiv, plotlyLineData, plotlyLineLayout);
    }

    function getBelowQuartile(quartile, unit) {
      var belowQuartile = [];
      var counts = {};
      var belowQuartileObj = {};
      var data = unit === "weeks" ? weeksData : chaptersData;
      var stats = unit === "weeks" ? weeksStats : chaptersStats;

      // get all students below quartile
      for (var i = 0; i < data.length; i++) {
        for (var j = 0; j < data[i].length; j++) {
          if (data[i][j] < stats[i][quartile]) {
            belowQuartile.push(users[j]["email"]);
          }
        }
      }
      // aggregate
      for (var i = 0; i < belowQuartile.length; i++) {
        var num = belowQuartile[i];
        counts[num] = counts[num] ? counts[num] + 1 : 1;
      }
      // reformat
      for (var key in counts) {
        if (counts[key] in belowQuartileObj) {
          belowQuartileObj[counts[key]].push(key);
        } else {
          belowQuartileObj[counts[key]] = [key];
        }
      }
      return belowQuartileObj;
    }

    var plotlyLineData = [];

    var plotlyLineClassStats = {
      weeks: {
        q1: {
          type: "scatter",
          mode: "lines",
          name: "class_q1",
          x: weeksDates,
          y: weeksQ1,
          line: {
            dash: "dashdot",
            width: 1,
            color: "#17BE00",
          },
        },
        median: {
          type: "scatter",
          mode: "lines",
          name: "class_median",
          x: weeksDates,
          y: weeksMedian,
          line: {
            dash: "dashdot",
            width: 2,
            color: "#17BECF",
          },
        },
        q3: {
          type: "scatter",
          mode: "lines",
          name: "class_q3",
          x: weeksDates,
          y: weeksQ3,
          line: {
            dash: "dashdot",
            width: 1,
            color: "#17BE00",
          },
        },
      },
      chapters: {
        q1: {
          type: "scatter",
          mode: "lines",
          name: "class_q1",
          x: chaptersDates,
          y: chaptersQ1,
          line: {
            dash: "dashdot",
            width: 1,
            color: "#17BE00",
          },
        },
        median: {
          type: "scatter",
          mode: "lines",
          name: "class_median",
          x: chaptersDates,
          y: chaptersMedian,
          line: {
            dash: "dashdot",
            width: 2,
            color: "#17BECF",
          },
        },
        q3: {
          type: "scatter",
          mode: "lines",
          name: "class_q3",
          x: chaptersDates,
          y: chaptersQ3,
          line: {
            dash: "dashdot",
            width: 1,
            color: "#17BE00",
          },
        },
      },
    };

    function addClassStats(arr, buttonName) {
      arr.push(plotlyLineClassStats[buttonName]["q3"]);
      arr.push(plotlyLineClassStats[buttonName]["median"]);
      arr.push(plotlyLineClassStats[buttonName]["q1"]);
    }

    addClassStats(plotlyLineData, "weeks");

    var belowQuartileObj = {};
    belowQuartileObj["weeks"] = getBelowQuartile("median", "weeks");
    belowQuartileObj["chapters"] = getBelowQuartile("median", "chapters");

    function calculateSteps(quartile, unit) {
      var belowQuartileSteps = Object.keys(belowQuartileObj[unit]).map(
        function (x) {
          return parseInt(x, 10);
        }
      );
      belowQuartileSteps.sort(Plotly.d3.descending);

      // calculate steps
      var steps = [];
      steps.push({
        label: parseInt(belowQuartileSteps[0]) + 1,
        method: "skip",
        execute: false,
      });

      for (var i = 0; i < belowQuartileSteps.length; i++) {
        var step = {
          label: belowQuartileSteps[i],
          method: "skip",
          execute: false,
        };
        steps.push(step);
      }
      return steps;
    }

    var updatemenusLine = [
      {
        buttons: [
          {
            name: "weeks",
            args: [{ title: "Total Reading time per week." }],
            label: "Weeks",
            method: "update",
          },
          {
            name: "chapters",
            args: [{ title: "Total Reading time per chapter." }],
            label: "Chapters",
            method: "update",
          },
        ],
        direction: "left",
        pad: { r: 10, t: 10 },
        showactive: true,
        type: "buttons",
        x: 1,
        xanchor: "right",
        y: 1.3,
        yanchor: "top",
      },
    ];

    var plotlyLineLayout = {
      title: "OpenDSA Total Reading Time.",
      updatemenus: updatemenusLine,
      xaxis: {
        autorange: true,
        range: [weeksDates[0], weeksDates[weeksDates.length - 1]],
        rangeselector: {
          buttons: [{ step: "all" }],
        },
        rangeslider: {
          range: [weeksDates[0], weeksDates[weeksDates.length - 1]],
        },
        type: "date",
      },
      yaxis: {
        autorange: true,
        type: "linear",
      },
      sliders: [
        {
          pad: { t: 85 },
          currentvalue: {
            xanchor: "left",
            prefix: "Students with (",
            suffix: ") week(s) below class median.",
            font: {
              color: "#888",
              size: 20,
            },
          },
          steps: calculateSteps("median", "weeks"),
        },
      ],
      showlegend: true,
      legend: {
        x: 1.17,
        xanchor: "right",
        y: 1,
      },
    };

    var plotlyLineDiv = $("#plotlyLineDiv")[0];
    var promise = new Promise((resolve, reject) => {
      Plotly.newPlot(plotlyLineDiv, plotlyLineData, plotlyLineLayout).then(
        () => {
          resolve();
        }
      );
    });

    plotlyLineDiv.on("plotly_sliderchange", function (e) {
      selectize_line.clear();
      var stepLabel = e.step.label;
      var chosenStudents = [];
      var selectedStudents = Object.keys(
        belowQuartileObj[currentLineTab]
      ).includes(stepLabel)
        ? belowQuartileObj[currentLineTab][stepLabel]
        : [];
      if (selectedStudents) {
        for (var i = 0; i < selectedStudents.length; i++) {
          chosenStudents.push(usersEmailHash[selectedStudents[i]]);
        }
      }

      plotlyLineLayout.sliders[0].currentvalue.suffix =
        currentLineTab === "weeks"
          ? ") week(s) below class median."
          : ") chapter(s) below class median.";
      updateLinePlot(chosenStudents);
    });

    // event handler to select points and show dataTables
    plotlyLineDiv.on("plotly_buttonclicked", function (e) {
      selectize_line.clear();
      var buttonName = e.button.name;

      if (["weeks", "chapters"].includes(buttonName)) {
        currentLineTab = buttonName;
        plotlyLineLayout.sliders[0].active = 0;
        plotlyLineLayout.sliders[0].currentvalue.suffix =
          currentLineTab === "weeks"
            ? ") week(s) below class median."
            : ") chapter(s) below class median.";
        updateLinePlot();
      }
    });
    return promise;
  }

  // Initializes Plotly Bar plot
  function initBarPlot(vizData, lookups) {
    var chaptersNames = lookups["chaptersNames"];
    var chaptersNamesIds = lookups["chaptersNamesIds"];
    var chaptersData = vizData["chaptersData"];
    var chaptersTotalData = vizData["chaptersTotalData"];
    var chaptersHash = lookups["chaptersHash"];
    var modulesData = vizData["modulesData"];
    var modulesTotalData = vizData["modulesTotalData"];
    var modulesHash = lookups["modulesHash"];
    var modulesNamesHash = lookups["modulesNamesHash"];
    var modulesChaptersHash = lookups["modulesChaptersHash"];
    var usersHash = lookups["usersHash"];
    var chapters = lookups["chapters"];
    var users = lookups["users"];
    var currentBarTab = "chapters";

    var plotlyBarData = [
      {
        x: chaptersNames,
        y: chaptersTotalData,
        type: "bar",
      },
    ];

    // plotly menu
    var updatemenus = [
      {
        buttons: [
          {
            name: "chapters",
            args: [
              {
                title: "Students total reading time per chapter.",
              },
            ],
            label: "Chapters",
            method: "update",
          },
          {
            name: "modules",
            args: [
              {
                title: "Students total reading time per module.",
              },
            ],
            label: "Modules",
            method: "update",
          },
        ],
        direction: "left",
        pad: { r: 10, t: 10 },
        showactive: true,
        type: "buttons",
        x: 1,
        xanchor: "right",
        y: 1.2,
        yanchor: "top",
      },
    ];

    // plotly layout
    var plotlyBarLayout = {
      title: "Students total reading time.",
      updatemenus: updatemenus,
      yaxis: {
        title: "Reading time in mins.",
        autorange: true,
        showgrid: true,
        zeroline: true,
        gridcolor: "rgb(255, 255, 255)",
        gridwidth: 1,
        zerolinecolor: "rgb(255, 255, 255)",
        zerolinewidth: 2,
      },
      margin: {
        l: 50,
        r: 50,
        b: 50,
        t: 50,
      },
      paper_bgcolor: "rgb(243, 243, 243)",
      plot_bgcolor: "rgb(243, 243, 243)",
      showlegend: true,
      legend: {
        x: 1.07,
        xanchor: "right",
        y: 1,
      },
    };
    var plotlyBarDiv = $("#plotlyBarDiv")[0];

    var promise = new Promise((resolve, reject) => {
      Plotly.newPlot(plotlyBarDiv, plotlyBarData, plotlyBarLayout).then(() => {
        resolve();
      });
    });

    plotlyBarDiv.on("plotly_buttonclicked", function (e) {
      currentBarTab = e.button.name;

      if (currentBarTab == "chapters") {
        $("#sel_modules").hide();
        $("#sel_chapters").show();
        updateBarPlot(
          selectize_bar_user.items,
          selectize_bar_ch.items,
          [],
          "chapters"
        );
      } else {
        $("#sel_modules").show();
        $("#sel_chapters").hide();
        updateBarPlot(
          selectize_bar_user.items,
          [],
          selectize_bar_mod.items,
          "modules"
        );
      }
    });

    //
    // selectize code
    // initialize selectize for box plot
    $selectize_bar_user = $("#select-for-bar-user").selectize({
      plugins: ["remove_button", "drag_drop"],
      persist: false,
      maxItems: null,
      valueField: "id",
      labelField: "name",
      searchField: ["first_name", "last_name", "email"],
      sortField: [
        { field: "first_name", direction: "asc" },
        { field: "last_name", direction: "asc" },
      ],
      options: users,
      render: {
        item: function (item, escape) {
          var name = formatName(item);
          return (
            "<div>" +
            (name ? '<span class="name">' + escape(name) + "</span>" : "") +
            (item.email
              ? '<span class="email">' + escape(item.email) + "</span>"
              : "") +
            "</div>"
          );
        },
        option: function (item, escape) {
          var name = formatName(item);
          var label = name || item.email;
          var caption = name ? item.email : null;
          return (
            "<div>" +
            '<span class="label">' +
            escape(label) +
            "</span>" +
            (caption
              ? '<span class="caption">' + escape(caption) + "</span>"
              : "") +
            "</div>"
          );
        },
      },
      createFilter: function (input) {
        var regexpA = new RegExp("^" + REGEX_EMAIL + "$", "i");
        var regexpB = new RegExp("^([^<]*)<" + REGEX_EMAIL + ">$", "i");
        return regexpA.test(input) || regexpB.test(input);
      },
      create: function (input) {
        if (new RegExp("^" + REGEX_EMAIL + "$", "i").test(input)) {
          return { email: input };
        }
        var match = input.match(
          new RegExp("^([^<]*)<" + REGEX_EMAIL + ">$", "i")
        );
        if (match) {
          var name = $.trim(match[1]);
          var pos_space = name.indexOf(" ");
          var first_name = name.substring(0, pos_space);
          var last_name = name.substring(pos_space + 1);

          return {
            email: match[2],
            first_name: first_name,
            last_name: last_name,
          };
        }
        return false;
      },
    });

    var selectize_bar_user = $selectize_bar_user[0].selectize;

    $("select#select-for-bar-user.selectized").each(function () {
      var update = function (e) {
        updateBarPlot(
          $(this).val(),
          selectize_bar_ch.items,
          selectize_bar_mod.items,
          currentBarTab
        );
      };
      $(this).on("change", update);
    });

    var $selectize_bar_ch = $("#select-for-bar-ch").selectize({
      plugins: ["remove_button", "drag_drop"],
      persist: false,
      maxItems: null,
      valueField: "ch_id",
      labelField: "ch_name",
      searchField: ["ch_name"],
      sortField: [{ field: "ch_id", direction: "asc" }],
      options: chaptersNamesIds,
      render: {
        item: function (item, escape) {
          return (
            "<div>" + "<span>" + escape(item.ch_name) + "</span>" + "</div>"
          );
        },
        option: function (item, escape) {
          return (
            "<div>" + "<span>" + escape(item.ch_name) + "</span>" + "</div>"
          );
        },
      },
    });

    var selectize_bar_ch = $selectize_bar_ch[0].selectize;

    $("select#select-for-bar-ch.selectized").each(function () {
      var update = function (e) {
        updateBarPlot(selectize_bar_user.items, $(this).val(), [], "chapters");
      };
      $(this).on("change", update);
    });

    $selectize_bar_mod = $("#select-for-bar-mod").selectize({
      plugins: ["remove_button", "drag_drop"],
      persist: false,
      maxItems: null,
      valueField: "mod_id",
      labelField: "mod_name",
      searchField: ["ch_name", "mod_name"],
      sortField: [
        { field: "ch_id", direction: "asc" },
        { field: "mod_id", direction: "asc" },
      ],
      options: chapters,
      render: {
        item: function (item, escape) {
          return (
            "<div>" +
            "<span>" +
            escape(item.ch_name) +
            " - " +
            escape(item.mod_name) +
            "</span>" +
            "</div>"
          );
        },
        option: function (item, escape) {
          return (
            "<div>" +
            "<span>" +
            escape(item.ch_name) +
            " - " +
            escape(item.mod_name) +
            "</span>" +
            "</div>"
          );
        },
      },
    });

    var selectize_bar_mod = $selectize_bar_mod[0].selectize;
    $("#sel_modules").hide();

    $("select#select-for-bar-mod.selectized").each(function () {
      var update = function (e) {
        updateBarPlot(selectize_bar_user.items, [], $(this).val(), "modules");
      };
      $(this).on("change", update);
    });

    function updateBarPlot(selUsers, selChapters, selModules, mode) {
      var mode = mode || "chapters";
      var selUsers = selUsers || [];
      var selChapters = selChapters || [];
      var selModules = selModules || [];
      var plotlyBarData = [];
      var traceX = [];
      var traceY = [];
      var barmode = "";
      var title = plotlyBarLayout["title"];

      if (mode == "chapters") {
        if (selChapters.length) {
          for (var i = 0; i < selChapters.length; i++) {
            traceX.push(chaptersNames[chaptersHash[selChapters[i]]]);
          }
          if (selUsers.length) {
            for (var i = 0; i < selUsers.length; i++) {
              for (var j = 0; j < selChapters.length; j++) {
                traceY.push(
                  chaptersData[chaptersHash[selChapters[j]]][
                    usersHash[selUsers[i]]
                  ]
                );
              }
              plotlyBarData.push({
                x: traceX,
                y: traceY,
                name: formatName(users[usersHash[selUsers[i]]]),
                type: "bar",
              });
              traceY = [];
            }
            barmode = "group";
            title = "Selected students reading time grouped by chapter";
          } else {
            for (var j = 0; j < selChapters.length; j++) {
              traceY.push(chaptersTotalData[chaptersHash[selChapters[j]]]);
            }
            plotlyBarData.push({
              x: traceX,
              y: traceY,
              type: "bar",
            });
            title = "Total students' reading time grouped by chapter";
          }
        } else {
          plotlyBarData.push({
            x: chaptersNames,
            y: chaptersTotalData,
            type: "bar",
          });
          title = "Total students' reading time per chapter";
        }
      } else if (mode == "modules") {
        if (selModules.length) {
          for (var i = 0; i < selModules.length; i++) {
            traceX.push(modulesNamesHash[selModules[i]]);
          }
          if (selUsers.length) {
            for (var i = 0; i < selUsers.length; i++) {
              for (var j = 0; j < selModules.length; j++) {
                var ch_id = modulesChaptersHash[selModules[j]];
                traceY.push(
                  modulesData[ch_id][modulesHash[selModules[j]]][
                    usersHash[selUsers[i]]
                  ]
                );
              }
              plotlyBarData.push({
                x: traceX,
                y: traceY,
                name: formatName(users[usersHash[selUsers[i]]]),
                type: "bar",
              });
              traceY = [];
            }
            barmode = "group";
            title = "Selected students reading time grouped by module";
          } else {
            for (var j = 0; j < selModules.length; j++) {
              var ch_id = modulesChaptersHash[selModules[j]];
              traceY.push(modulesTotalData[ch_id][modulesHash[selModules[j]]]);
            }
            plotlyBarData.push({
              x: traceX,
              y: traceY,
              type: "bar",
            });
            title = "Total students' reading time grouped by module";
          }
        } else {
          plotlyBarData.push({
            x: chaptersNames,
            y: chaptersTotalData,
            type: "bar",
          });
          title = "Total students' reading time per module";
        }
      }

      if (barmode) {
        plotlyBarLayout["barmode"] = barmode;
      }
      plotlyBarLayout["title"] = title;
      Plotly.react(plotlyBarDiv, plotlyBarData, plotlyBarLayout);
    }

    return promise;
  }

  // Initializes Plotly section bar plot
  function initSecBarPlot(vizData, lookups) {
    var modulesNamesHash = lookups["modulesNamesHash"];
    var sectionsLookup = vizData["sectionsLookup"];
    var sectionsData = vizData["sectionsData"];
    var sectionsTotalData = vizData["sectionsTotalData"];
    var modulesChaptersHash = lookups["modulesChaptersHash"];
    var usersHash = lookups["usersHash"];
    var chapters = lookups["chapters"];
    var users = lookups["users"];

    var plotlySecBarData = [
      {
        x: [],
        y: [],
        type: "bar",
      },
    ];

    // plotly menu
    var updatemenus = [
      {
        direction: "left",
        pad: { r: 10, t: 10 },
        showactive: true,
        type: "buttons",
        x: 1,
        xanchor: "right",
        y: 1.2,
        yanchor: "top",
      },
    ];

    // plotly layout
    var plotlySecBarLayout = {
      title: "Please select a module to show time tracking for its sections.",
      updatemenus: updatemenus,
      yaxis: {
        title: "Reading time in mins.",
        autorange: true,
        showgrid: true,
        zeroline: true,
        gridcolor: "rgb(255, 255, 255)",
        gridwidth: 1,
        zerolinecolor: "rgb(255, 255, 255)",
        zerolinewidth: 2,
      },
      margin: {
        l: 50,
        r: 50,
        b: 100,
        t: 50,
      },
      paper_bgcolor: "rgb(243, 243, 243)",
      plot_bgcolor: "rgb(243, 243, 243)",
      showlegend: true,
      legend: {
        x: 1.07,
        xanchor: "right",
        y: 1,
      },
    };

    var plotlySecBarDiv = $("#plotlySecBarDiv")[0];

    var promise = new Promise((resolve, reject) => {
      Plotly.newPlot(
        plotlySecBarDiv,
        plotlySecBarData,
        plotlySecBarLayout
      ).then(() => {
        resolve();
      });
    });

    //
    // selectize code
    // initialize selectize for bar plot
    $selectize_user_sec = $("#select-for-user-sec").selectize({
      plugins: ["remove_button", "drag_drop"],
      persist: false,
      maxItems: null,
      valueField: "id",
      labelField: "name",
      searchField: ["first_name", "last_name", "email"],
      sortField: [
        { field: "first_name", direction: "asc" },
        { field: "last_name", direction: "asc" },
      ],
      options: users,
      render: {
        item: function (item, escape) {
          var name = formatName(item);
          return (
            "<div>" +
            (name ? '<span class="name">' + escape(name) + "</span>" : "") +
            (item.email
              ? '<span class="email">' + escape(item.email) + "</span>"
              : "") +
            "</div>"
          );
        },
        option: function (item, escape) {
          var name = formatName(item);
          var label = name || item.email;
          var caption = name ? item.email : null;
          return (
            "<div>" +
            '<span class="label">' +
            escape(label) +
            "</span>" +
            (caption
              ? '<span class="caption">' + escape(caption) + "</span>"
              : "") +
            "</div>"
          );
        },
      },
      createFilter: function (input) {
        var regexpA = new RegExp("^" + REGEX_EMAIL + "$", "i");
        var regexpB = new RegExp("^([^<]*)<" + REGEX_EMAIL + ">$", "i");
        return regexpA.test(input) || regexpB.test(input);
      },
      create: function (input) {
        if (new RegExp("^" + REGEX_EMAIL + "$", "i").test(input)) {
          return { email: input };
        }
        var match = input.match(
          new RegExp("^([^<]*)<" + REGEX_EMAIL + ">$", "i")
        );
        if (match) {
          var name = $.trim(match[1]);
          var pos_space = name.indexOf(" ");
          var first_name = name.substring(0, pos_space);
          var last_name = name.substring(pos_space + 1);

          return {
            email: match[2],
            first_name: first_name,
            last_name: last_name,
          };
        }
        return false;
      },
    });

    var selectize_user_sec = $selectize_user_sec[0].selectize;

    $("select#select-for-user-sec.selectized").each(function () {
      var update = function (e) {
        updateSecBarPlot($(this).val(), selectize_mod_sec.items);
      };
      $(this).on("change", update);
    });

    var $selectize_mod_sec = $("#select-for-mod-sec").selectize({
      create: true,
      persist: false,
      valueField: "mod_id",
      labelField: "mod_name",
      searchField: ["ch_name", "mod_name"],
      sortField: [
        { field: "ch_id", direction: "asc" },
        { field: "mod_id", direction: "asc" },
      ],
      options: chapters,
      render: {
        item: function (item, escape) {
          return (
            "<div>" +
            "<span>" +
            escape(item.ch_name) +
            " - " +
            escape(item.mod_name) +
            "</span>" +
            "</div>"
          );
        },
        option: function (item, escape) {
          return (
            "<div>" +
            "<span>" +
            escape(item.ch_name) +
            " - " +
            escape(item.mod_name) +
            "</span>" +
            "</div>"
          );
        },
      },
    });

    var selectize_mod_sec = $selectize_mod_sec[0].selectize;

    $("select#select-for-mod-sec.selectized").each(function () {
      var update = function (e) {
        updateSecBarPlot(selectize_user_sec.items, $(this).val());
      };
      $(this).on("change", update);
    });

    function updateSecBarPlot(selUsers, selModule) {
      var selUsers = selUsers || [];
      var selModule = selModule || null;
      var selChapter = selModule ? modulesChaptersHash[selModule] : null;
      var moduleName = selModule ? modulesNamesHash[selModule] : null;
      var sectionsNamesArr =
        selModule && selChapter ? sectionsLookup[selChapter][selModule] : [];
      var plotlySecBarData = [];
      var traceX = [];
      var traceY = [];
      var barmode = "";
      var title = plotlySecBarLayout["title"];

      if (selModule) {
        traceX = sectionsNamesArr;
        if (selUsers.length) {
          for (var i = 0; i < selUsers.length; i++) {
            for (var j = 0; j < sectionsNamesArr.length; j++) {
              traceY.push(
                sectionsData[selChapter][selModule][j][usersHash[selUsers[i]]]
              );
            }
            plotlySecBarData.push({
              x: traceX,
              y: traceY,
              name: formatName(users[usersHash[selUsers[i]]]),
              type: "bar",
            });
            traceY = [];
          }
          barmode = "group";
          title = `Selected students reading time for sections of <b>${moduleName}</b> module`;
        } else {
          for (var j = 0; j < sectionsNamesArr.length; j++) {
            traceY.push(sectionsTotalData[selChapter][selModule][j]);
          }
          plotlySecBarData.push({
            x: traceX,
            y: traceY,
            type: "bar",
          });
          title = `Total students' reading time for sections of <b>${moduleName}</b> module`;
        }
      } else {
        title =
          "Please select a module to show time tracking for its sections.";
      }

      if (barmode) {
        plotlySecBarLayout["barmode"] = barmode;
      }
      plotlySecBarLayout["title"] = title;
      Plotly.react(plotlySecBarDiv, plotlySecBarData, plotlySecBarLayout);
    }

    return promise;
  }

  // Uses lookup data and time tracking aggregated data to initilaize plotly graphs
  function initViz(vizData, lookups) {
    var promise = new Promise((resolve, reject) => {
      initBoxPlot(vizData, lookups).then(() => {
        initLinePlot(vizData, lookups).then(() => {
          initBarPlot(vizData, lookups).then(() => {
            initSecBarPlot(vizData, lookups).then(() => {
              resolve();
            });
          });
        });
      });
    });

    return promise;
  }

  // Returns formated date
  function getTimestamp(date, format) {
    var format = format || "yyyy-mm-dd";
    var month = date.getMonth() + 1;
    if (month < 10) month = "0" + month;
    var day = date.getDate();
    if (day < 10) day = "0" + day;
    var hour = date.getHours();
    if (hour < 10) hour = "0" + hour;
    var minute = date.getMinutes();
    if (minute < 10) minute = "0" + minute;
    var second = date.getSeconds();
    if (second < 10) second = "0" + second;

    if (format == "yyyymmdd") {
      return [date.getFullYear(), month, day].join("");
    } else {
      return [date.getFullYear(), month, day].join("-");
    }
  }

  function init(count) {
    var count = count || 1;
    var promise = new Promise((resolve, reject) => {
      getLookupData(odsaStore)
        .then((lookups) => {
          getTimeTrackingData(odsaStore, lookups, count)
            .then((vizData) => {
              $("#reload_data").show();
              $("#generate_data").show();
              $("#export_students_csv").show();
              $(".accordionjs").show();
              initViz(vizData, lookups).then(() => {
                $("#tools-accordion").accordionjs({
                  activeIndex: false,
                  closeAble: true,
                });
                $("#tools-accordion-exs").accordionjs({
                  activeIndex: false,
                  closeAble: true,
                });
                initExTools(lookups);
                resolve();
              });
            })
            .catch((err) => {
              console.log(err);
              errDialog(err);
            });
        })
        .catch((err) => {
          console.log(err);
          errDialog(err);
        });
    });
    return promise;
  }

  function errDialog(msg) {
    $.confirm({
      title: "OpenDSA Analytics tools.",
      type: "red",
      escapeKey: true,
      content: msg,
      theme: "bootstrap",
      icon: "fa fa-database",
      animation: "scale",
      closeAnimation: "scale",
      opacity: 0.5,
      container: "body",
      closeIcon: true,
      backgroundDismiss: true,
      columnClass: "col-md-8 col-md-offset-8",
      buttons: {
        confirm: {
          text: "Ok",
          btnClass: "btn-success",
        },
      },
    });
  }

  // As instructors they might need to reload time tracking data from the begining of the term.
  // Deletes the existing data in the local storage and starts all over.
  function reloadVizData(count) {
    updateStoreData(odsaStore, "odsaLoadDataCount", count).then(() => {
      deleteStoreData(odsaStore, "odsaTimeTrackingData").then(() => {
        deleteStoreData(odsaStore, "odsaLookupData").then(() => {
          init(count).then(() => {
            location.reload();
          });
        });
      });
    });
  }

  function initExTools(lookups) {
    var users = lookups["users"];
    var modulesGradable = lookups["modulesGradable"];

    var selectize_modules; // module picker
    var selectize_exoverview_exs; // exercise picker (exercise overview tab)

    var EXERCISE_OVERVIEW_MODE = false;

    /* ---------------- UI helpers ---------------- */
    function clearContainers() {
      $("#multi-container").hide(); // module dropdown row
      $("#exercise-overview-container").hide(); // exercise dropdown row
      $("#exercise-overview-actions").hide(); // export button row
      $("#single-container").hide(); // single-student
      $("#single-container-exs").hide(); // single-student exercises
      $("#mst-container").hide(); // big module table
      $("#display_table").html("");
    }

    function getSelectedModuleId() {
      return selectize_modules &&
        typeof selectize_modules.getValue === "function"
        ? selectize_modules.getValue()
        : "";
    }
    function getSelectedExerciseSectionId() {
      return selectize_exoverview_exs &&
        typeof selectize_exoverview_exs.getValue === "function"
        ? selectize_exoverview_exs.getValue()
        : "";
    }

    function updateExportEnabled() {
      var enabled =
        EXERCISE_OVERVIEW_MODE &&
        !!getSelectedModuleId() &&
        !!getSelectedExerciseSectionId();
      $("#btn-exercise-overview-csv")
        .prop("disabled", !enabled)
        .toggleClass("disabled", !enabled)
        .css("pointer-events", enabled ? "auto" : "none");
    }

    function resetExercisePicker() {
      if (!selectize_exoverview_exs) return;
      selectize_exoverview_exs.clear(true);
      selectize_exoverview_exs.clearOptions();
      selectize_exoverview_exs.renderCache = { item: {}, option: {} };
      selectize_exoverview_exs.close();
      updateExportEnabled();
    }

    /* ---------------- Tabs ---------------- */
    $("#ex-btn-exercise-overview")
      .off("click")
      .on("click", function () {
        EXERCISE_OVERVIEW_MODE = true;
        clearContainers();
        $("#multi-container").show(); // 1) module
        $("#exercise-overview-container").show(); // 2) exercise
        $("#exercise-overview-actions").show(); // 3) export
        resetExercisePicker();
      });

    $("#ex-btn-multi")
      .off("click")
      .on("click", function () {
        EXERCISE_OVERVIEW_MODE = false;
        clearContainers();
        $("#multi-container").show(); // render table on change
      });

    $("#ex-btn-single")
      .off("click")
      .on("click", function () {
        EXERCISE_OVERVIEW_MODE = false;
        clearContainers();
        $("#single-container").show();
        $("#single-container-exs").show();
      });

    /* ---------------- Selectize: Modules ---------------- */
    var $selMods = $("#select-for-modules").selectize({
      persist: false,
      valueField: "ch_mod_id",
      labelField: "mod_name",
      searchField: ["mod_name"],
      sortField: [
        { field: "ch_id", direction: "asc" },
        { field: "mod_id", direction: "asc" },
      ],
      options: modulesGradable,
      render: {
        item: function (item, esc) {
          return (
            "<div><span>" +
            esc(item.ch_name) +
            " - " +
            esc(item.mod_name) +
            "</span></div>"
          );
        },
        option: function (item, esc) {
          return (
            "<div><span>" +
            esc(item.ch_name) +
            " - " +
            esc(item.mod_name) +
            "</span></div>"
          );
        },
      },
    });
    selectize_modules = $selMods[0].selectize;

    $("select#select-for-modules.selectized")
      .off("change")
      .on("change", async function () {
        var modId = $(this).val();

        if (EXERCISE_OVERVIEW_MODE) {
          resetExercisePicker();
          await populateExercisesFromModule(modId);
          updateExportEnabled();
          return; // don't render big table in this tab
        }

        if (modId) {
          // existing behavior for multi-student table
          handleModuleDisplay(modId);
        }
      });

    var selectize_students;

    var $selStudents = $("#select-for-students").selectize({
      valueField: "id",
      labelField: "name",
      searchField: ["first_name", "last_name", "email"],
      sortField: [
        { field: "first_name", direction: "asc" },
        { field: "last_name", direction: "asc" },
      ],
      options: users, // <— lookups["users"]
      render: {
        item: function (item, esc) {
          var name = [item.first_name, item.last_name]
            .filter(Boolean)
            .join(" ");
          return (
            "<div>" +
            (name ? '<span class="name">' + esc(name) + "</span>" : "") +
            (item.email
              ? ' <span class="email">' + esc(item.email) + "</span>"
              : "") +
            "</div>"
          );
        },
        option: function (item, esc) {
          var name = [item.first_name, item.last_name]
            .filter(Boolean)
            .join(" ");
          var label = name || item.email || "User " + item.id;
          var caption = name ? item.email : null;
          return (
            "<div>" +
            '<span class="label">' +
            esc(label) +
            "</span>" +
            (caption
              ? ' <span class="caption">' + esc(caption) + "</span>"
              : "") +
            "</div>"
          );
        },
      },
    });
    selectize_students = $selStudents[0].selectize;

    // When a student is chosen, fetch their exercise list for the 2nd dropdown
    $("select#select-for-students.selectized")
      .off("change")
      .on("change", function () {
        var userId = selectize_students.getValue();
        if (userId) handleSelectStudent(userId, ODSA_DATA.course_offering_id);
      });

    /* -------- Selectize: exercises for the chosen student ---------- */
    var selectize_students_exs;

    var $selStuEx = $("#select-for-students-exs").selectize({
      valueField: "key", // we’ll set this via handleSelectStudent
      labelField: "name",
      searchField: ["name"],
      sortField: [{ field: "name", direction: "asc" }],
      options: [], // filled after a student is picked
      render: {
        item: function (item, esc) {
          return item.attempt_flag
            ? "<div><span class='name'>" + esc(item.name) + "</span></div>"
            : "<div></div>";
        },
        option: function (item, esc) {
          return item.attempt_flag
            ? "<div><span class='name'>" + esc(item.name) + "</span></div>"
            : "<div></div>";
        },
      },
    });
    selectize_students_exs = $selStuEx[0].selectize;

    // When a student exercise is chosen, render the tables
    $("select#select-for-students-exs.selectized")
      .off("change")
      .on("change", function () {
        var inst_section_id = selectize_students_exs.getValue();
        var userId = selectize_students.getValue();
        if (userId && inst_section_id) {
          $("#display_table").html("");
          handleDisplay(userId, inst_section_id); // existing function renders progress/attempts
        }
      });

    /* -------- Selectize: Exercise picker (Exercise Overview tab) ------ */
    var $selEx = $("#select-for-exercises-ov").selectize({
      valueField: "section_id", // route-ready inst_section_id
      labelField: "name",
      searchField: ["name"],
      sortField: [{ field: "name", direction: "asc" }],
      options: [],
      render: {
        item: function (item, esc) {
          return "<div><span class='name'>" + esc(item.name) + "</span></div>";
        },
        option: function (item, esc) {
          return "<div><span class='name'>" + esc(item.name) + "</span></div>";
        },
      },
    });
    selectize_exoverview_exs = $selEx[0].selectize;

    $("select#select-for-exercises-ov.selectized")
      .off("change")
      .on("change", function () {
        updateExportEnabled();
      });

    /* ---------------- Populate exercises for module ---------------- */
    async function populateExercisesFromModule(chModId) {
      if (!chModId || !selectize_exoverview_exs) return;

      selectize_exoverview_exs.clearOptions();
      selectize_exoverview_exs.renderCache = { item: {}, option: {} };

      try {
        var data = await $.ajax({
          url:
            "/course_offerings/" +
            ODSA_DATA.course_offering_id +
            "/modules/" +
            chModId +
            "/progresses",
          type: "get",
        });

        var seen = {};
        (data.exercises || []).forEach(function (ex) {
          var sectionId =
            ex.inst_section_id ||
            (ex.inst_section && ex.inst_section.id) ||
            ex.section_id ||
            ex.inst_book_section_id ||
            ex.id;

          if (!sectionId || seen[sectionId]) return;
          seen[sectionId] = true;

          var name =
            (ex.inst_exercise && ex.inst_exercise.name) ||
            ex.name ||
            "Exercise " + sectionId;

          selectize_exoverview_exs.addOption({
            section_id: String(sectionId),
            name: name,
          });
        });

        selectize_exoverview_exs.refreshOptions(true); // rebuild dropdown
        updateExportEnabled();
      } catch (err) {
        console.error("Failed to load exercises for module", chModId, err);
      }
    }

    /* ---------------- Fetch + CSV helpers (summary only) ------------- */
    function fetchSection(userId, instSectionId) {
      return $.ajax({
        url: "/course_offerings/" + userId + "/" + instSectionId + "/section",
        type: "get",
      });
    }

    const SUMMARY_HEADER = [
      "StudentId",
      "ExerciseInstSectionId",
      "ExerciseName",
      "PointsPossible",
      "CurrentScore",
      "HighestScore",
      "TotalCorrect",
      "TotalAttempts",
      "PointsEarned",
      "ProficientDate",
      "FirstDone",
      "LastDone",
    ];

    function q(v) {
      var s = v == null ? "" : String(v);
      return '"' + s.replace(/"/g, '""') + '"';
    }
    function csv(arr) {
      return arr.map(q).join(",");
    }

    // Exactly ONE summary row per student/exercise
    async function rowsForStudentOnExercise(stu, instSectionId) {
      try {
        const data = await fetchSection(stu.id, instSectionId);

        const prog =
          (data &&
            data.odsa_exercise_progress &&
            data.odsa_exercise_progress[0]) ||
          {};
        const attempts = Array.isArray(data && data.odsa_exercise_attempts)
          ? data.odsa_exercise_attempts
          : [];
        const meta = data && data.inst_book_section_exercise;

        const exName =
          (data && data.inst_section && data.inst_section.name) ||
          (meta && meta.inst_exercise && meta.inst_exercise.name) ||
          "";

        const pointsPossible = meta && meta.points != null ? meta.points : "";
        const pointsEarned = prog.proficient_date ? pointsPossible || 0 : 0;

        return [
          csv([
            stu.id,
            instSectionId,
            exName,
            pointsPossible,
            prog.current_score ?? "",
            prog.highest_score ?? "",
            prog.total_correct ?? "",
            attempts.length,
            pointsEarned,
            prog.proficient_date || "N/A",
            prog.first_done || "N/A",
            prog.last_done || "N/A",
          ]),
        ];
      } catch (err) {
        console.warn("Detail fetch failed", {
          userId: stu.id,
          instSectionId,
          err,
        });
        return [
          csv([
            stu.id,
            instSectionId,
            "ERROR",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
          ]),
        ];
      }
    }

    async function exportExerciseCSV(instSectionId) {
      const students = Array.isArray(users) ? users.slice() : [];
      if (!students.length) {
        alert("No students found.");
        return;
      }

      const rows = [csv(SUMMARY_HEADER)];
      const CONCURRENCY = 6;
      let i = 0,
        active = 0;
      const running = [];

      async function work(stu) {
        rows.push(...(await rowsForStudentOnExercise(stu, instSectionId)));
      }

      while (i < students.length) {
        while (active < CONCURRENCY && i < students.length) {
          active++;
          running.push(work(students[i++]).finally(() => active--));
        }
        // eslint-disable-next-line no-await-in-loop
        await new Promise((r) => setTimeout(r, 20));
      }
      await Promise.all(running);

      const blob = new Blob([rows.join("\n")], {
        type: "text/csv;charset=utf-8",
      });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `exercise_overview_${instSectionId}_${new Date()
        .toISOString()
        .slice(0, 10)}.csv`;
      document.body.appendChild(a);
      a.click();
      URL.revokeObjectURL(url);
      a.remove();
    }

    // ONE click handler (matches HAML id)
    $(document)
      .off("click", "#btn-exercise-overview-csv")
      .on("click", "#btn-exercise-overview-csv", async function (e) {
        e.preventDefault();
        if ($(this).prop("disabled")) return;
        var sectionId = getSelectedExerciseSectionId();
        if (!sectionId) {
          alert("Pick an exercise first.");
          return;
        }
        await exportExerciseCSV(sectionId);
      });

    function handleModuleDisplay(mod_id) {
      if (EXERCISE_OVERVIEW_MODE) {
        return;
      }
      $.ajax({
        url: `/course_offerings/${ODSA_DATA.course_offering_id}/modules/${mod_id}/progresses`,
        type: "get",
      })
        .done(function (data) {
          var exHeader = $("#exercise-info-header");
          var headers = $("#mst-header-row");
          var tbody = $("#mst-body");
          var exInfoColStartIdx = 8;
          headers.children().slice(exInfoColStartIdx).remove();
          tbody.empty();

          // create a column for each exercise
          var points_possible = 0;
          for (var i = 0; i < data.exercises.length; i++) {
            var ex = data.exercises[i];
            ex.points = parseFloat(ex.points);
            points_possible += ex.points;
            headers.append(
              "<th>" + ex.inst_exercise.name + " (" + ex.points + "pts)</th>"
            );
          }
          exHeader.attr("colSpan", data.exercises.length);

          var enrollments = {};
          for (i = 0; i < data.enrollments.length; i++) {
            var enrollment = data.enrollments[i];
            enrollments[enrollment.user_id] = enrollment;
          }

          // create a row for each student
          var html = "";
          for (i = 0; i < data.students.length; i++) {
            var student = data.students[i];
            var have_ex_data = false;
            if (enrollments[student.id]) {
              student = enrollments[student.id].user;
              have_ex_data = true;
            }
            html += "<tr>";
            html += "<td>" + student.first_name + "</td>";
            html += "<td>" + student.last_name + "</td>";
            html += "<td>" + student.email + "</td>";
            if (have_ex_data) {
              var eps = student.odsa_exercise_progresses;
              var mp = student.odsa_module_progresses[0];
              var latest_proficiency = new Date(0);
              var exhtml = "";
              // match up exercises and exercise progresses
              for (var j = 0; j < data.exercises.length; j++) {
                var found = false;
                var ex = data.exercises[j];
                for (var k = 0; k < eps.length; k++) {
                  if (ex.id === eps[k].inst_book_section_exercise_id) {
                    if (eps[k].highest_score >= ex.threshold) {
                      exhtml += '<td class="success">' + ex.points + "</td>";
                      var pdate = new Date(eps[k].proficient_date);
                      if (pdate > latest_proficiency) {
                        latest_proficiency = pdate;
                      }
                    } else {
                      exhtml += "<td>0</td>";
                    }
                    found = true;
                    break;
                  }
                }
                if (!found) {
                  exhtml += "<td>0</td>";
                }
              }
              html +=
                "<td>" +
                parseFloat((mp.highest_score * points_possible).toFixed(2)) +
                "</td>";
              html += "<td>" + points_possible + "</td>";
              html +=
                "<td>" +
                (mp.created_at
                  ? new Date(mp.created_at).toLocaleString()
                  : "N/A") +
                "</td>";
              html +=
                "<td>" +
                (mp.proficient_date
                  ? new Date(mp.proficient_date).toLocaleString()
                  : "N/A") +
                "</td>";
              html +=
                "<td>" +
                (latest_proficiency.getTime() > 0
                  ? latest_proficiency.toLocaleString()
                  : "N/A") +
                "</td>";
              html += exhtml;
            } else {
              // student has not attempted any exercise in this module
              html +=
                "<td>0</td> <td>" +
                points_possible +
                "</td> <td>N/A</td> <td>N/A</td> <td>N/A</td>";
              for (var j = 0; j < data.exercises.length; j++) {
                html += "<td>0</td>";
              }
            }
            html += "</tr>";
          }
          tbody.append(html);
          $("#mst-container").css("display", "");
        })
        .fail(function (error) {
          console.log(error);
          try {
          } catch (ex) {}
        })
        .always(function () {});
    }

    function handleDisplay(user_id, inst_section_id) {
      //GET /course_offerings/:user_id/:inst_section_id
      var request = `/course_offerings/${user_id}/${inst_section_id}/section`;

      $.ajax({
        url: request,
        type: "get",
        data: $(this).serialize(),
      })
        .done(function (data) {
          if (
            data.odsa_exercise_progress.length == 0 ||
            data.odsa_exercise_attempts.length == 0
          ) {
            var p =
              '<p style="font-size:24px; align=center;"> You have not Attempted this exercise <p>';
            $("#display_table").html(p);
          } else if (
            data.odsa_exercise_attempts[0].pe_score != null ||
            data.odsa_exercise_attempts[0].pe_steps_fixed != null
          ) {
            var khan_ac_exercise = true;
            var header =
              '<p style="font-size:24px; align=center;"> OpenDSA Progress Table<p>';
            header += '<table class="table"><thead>';
            header += buildProgressHeader(khan_ac_exercise) + "</thead>";
            var elem = "<tbody>";
            elem += getFieldMember(
              data.inst_section,
              data.odsa_exercise_progress[0],
              data.odsa_exercise_attempts,
              data.inst_book_section_exercise,
              khan_ac_exercise
            );

            var header1 =
              '<p style="font-size:24px; align=center;"> OpenDSA Attempt Table' +
              data.odsa_exercise_attempts[0].question_name +
              "<p>";
            header1 += '<table class="table"><thead>';
            header1 += getAttemptHeader(khan_ac_exercise) + "</thead>";
            var elem1 = "<tbody>";
            var proficiencyFlag = -1;
            for (var i = 0; i < data.odsa_exercise_attempts.length; i++) {
              if (
                data.odsa_exercise_attempts[i].earned_proficiency != null &&
                data.odsa_exercise_attempts[i].earned_proficiency &&
                proficiencyFlag == -1
              ) {
                proficiencyFlag = 1;
                elem1 += getAttemptMemeber(
                  data.odsa_exercise_attempts[i],
                  proficiencyFlag,
                  khan_ac_exercise
                );
                proficiencyFlag = 2;
              } else {
                elem1 += getAttemptMemeber(
                  data.odsa_exercise_attempts[i],
                  proficiencyFlag,
                  khan_ac_exercise
                );
              }
            }
            header1 += elem1;
            header += elem;
            header += "</tbody></table> ";
            header1 += "</tbody></table>";
            header += "<br>" + header1;
            $("#display_table").html(header);
          } else {
            var header =
              '<p style="font-size:24px; align=center;"> OpenDSA Progress Table<p>';
            header += '<table class="table table-bordered"><thead>';
            var elem = "<tbody>";
            header += buildProgressHeader() + "</thead>";
            elem += getFieldMember(
              data.inst_section,
              data.odsa_exercise_progress[0],
              data.odsa_exercise_attempts,
              data.inst_book_section_exercise
            );
            var header1 =
              '<p style="font-size:24px; align=center;"> OpenDSA Attempt Table <p>';
            header1 +=
              '<table class="table table-bordered table-hover"><thead>';
            var elem1 = "<tbody>";
            header1 += getAttemptHeader() + "</thead>";
            var proficiencyFlag = -1;
            for (var i = 0; i < data.odsa_exercise_attempts.length; i++) {
              if (
                data.odsa_exercise_attempts[i].earned_proficiency != null &&
                data.odsa_exercise_attempts[i].earned_proficiency &&
                proficiencyFlag == -1
              ) {
                proficiencyFlag = 1;
                elem1 += getAttemptMemeber(
                  data.odsa_exercise_attempts[i],
                  proficiencyFlag
                );
                proficiencyFlag = 2;
              } else {
                elem1 += getAttemptMemeber(
                  data.odsa_exercise_attempts[i],
                  proficiencyFlag
                );
              }
            }
            header1 += elem1;
            header += elem;
            header += "</tbody></table> ";
            header1 += "</tbody></table>";
            header += "<br>" + header1;
            $("#display_table").html(header);
          }

          //change_courses(data);
        })
        .fail(function (data) {
          console.log("AJAX request has FAILED");
        })
        .always(function () {});
    }

    function getFieldMember(sData, pData, attempts, instBookSecEx, khan_ex) {
      var member = "<tr>";
      var pointsEarned = pData.proficient_date ? instBookSecEx.points : 0;
      if (khan_ex == null || khan_ex == false) {
        member += "<td>" + pData.current_score + "</td>";
        member += "<td>" + pData.highest_score + "</td>";
      }
      member += "<td>" + pData.total_correct + "</td>";
      member += "<td>" + attempts.length + "</td>";
      member += "<td>" + pointsEarned + "</td>";
      member += "<td>" + instBookSecEx.points + "</td>";
      if (pData.proficient_date != null) {
        member +=
          "<td>" +
          pData.proficient_date.substring(0, 10) +
          " " +
          pData.proficient_date.substring(11, 16) +
          "</td>";
      } else {
        member += "<td>N/A</td>";
      }
      member +=
        "<td>" +
        pData.first_done.substring(0, 10) +
        " " +
        pData.first_done.substring(11, 16) +
        "</td>";
      member +=
        "<td>" +
        pData.last_done.substring(0, 10) +
        " " +
        pData.last_done.substring(11, 16) +
        "</td>";
      return member;
    }

    function buildProgressHeader(khan_ex) {
      var elem = "<tr>";
      if (khan_ex == null || khan_ex == false) {
        elem += "<th>Current Score</th>";
        elem += "<th>Highest Score</th>";
      }
      elem += "<th>Total Correct</th>";
      elem += "<th>Total Attempts</th>";
      elem += "<th>Points Earned</th>";
      elem += "<th>Points Possible</th>";
      elem += "<th>Proficient Date</th>";
      elem += "<th>First Done</th>";
      elem += "<th>Last Done</th>";
      //elem += '<th>Posted to Canvas?</th>';
      //elem += '<th>Time Posted</th></tr>';

      return elem;
    }

    function getAttemptHeader(khan_ex) {
      var head = "<tr>";
      if (khan_ex == null || khan_ex == false) {
        head += "<th>Question name</th>";
        head += "<th>Request Type</th>";
      } else {
        head += "<th>Pe Score</th>";
        head += "<th>Pe Steps</th>";
      }
      head += "<th>Correct</th>";
      head += "<th>Worth Credit</th>";
      head += "<th>Time Done</th>";
      head += "<th>Time Taken (s)</th>";
      return head;
    }

    function getAttemptMemeber(aData, j, khan_ex) {
      var memb = "<tr>";
      if (khan_ex == null || khan_ex == false) {
        memb = "";
        if (aData.earned_proficiency != null && j == 1) {
          memb += '<tr class="success"><td>' + aData.question_name + "</td>";
        } else {
          memb += "<tr><td>" + aData.question_name + "</td>";
        }
        memb += "<td>" + aData.request_type + "</td>";
      } else {
        memb += "<td>" + aData.pe_score + "</td>";
        memb += "<td>" + aData.pe_steps_fixed + "</td>";
      }

      memb += "<td>" + aData.correct + "</td>";
      memb += "<td>" + aData.worth_credit + "</td>";
      memb +=
        "<td>" +
        aData.time_done.substring(0, 10) +
        " " +
        aData.time_done.substring(11, 16) +
        "</td>";
      memb += "<td>" + aData.time_taken + "</td>";

      return memb;
    }

    function handleSelectStudent(user_id, course_offering_id) {
      //GET /course_offerings/:user_id/course_offering_id/exercise_list
      var request = `/course_offerings/${user_id}/${course_offering_id}/exercise_list`;

      $.ajax({
        url: request,
        type: "get",
        data: $(this).serialize(),
      })
        .done(function (data) {
          if (data.odsa_exercise_attempts.length === 0) {
            var p =
              '<p style="font-size:24px; align=center;"> Select a student name <p>';
          } else {
            var exercises = data["odsa_exercise_attempts"];
            var exercisesArr = [];
            var exerciseName = "";
            var exerciseAttemptFlag = false;
            for (const key in exercises) {
              var exercise = exercises[key];
              if (Array.isArray(exercise)) {
                exerciseName = exercise[0];
                if (exercise.length == 2 && exercise[1] == "attempt_flag") {
                  exerciseAttemptFlag = true;
                }
              }
              exercisesArr.push({
                key: key,
                name: exerciseName,
                attempt_flag: exerciseAttemptFlag,
              });
              exerciseAttemptFlag = false;
            }
            selectize_students_exs.clearOptions();
            selectize_students_exs.addOption(exercisesArr);
          }
          //change_courses(data);
        })
        .fail(function (data) {
          console.log("AJAX request has FAILED");
        });
    }
  }

  $("#reload_data").on("click", function (e) {
    e.preventDefault();
    var count = 2;

    getLookupData(odsaStore).then((lookups) => {
      getStoreData(odsaStore, "odsaLoadDataCount")
        .then((result) => {
          if (result && Object.keys(result).includes("data")) {
            count = result["data"] + 1 || count;
          }
          var termStartDate = new Date(
            lookups["term"]["starts_on"] + "T23:59:59-0000"
          );
          var termEndDate = new Date(
            lookups["term"]["ends_on"] + "T23:59:59-0000"
          );
          var currentDate = new Date();
          var trackingEndDate =
            termEndDate > currentDate ? currentDate : termEndDate;
          var diffTime = Math.abs(trackingEndDate - termStartDate);
          var diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
          var loadTime = ((diffDays * count) / 60).toFixed(2);

          $.confirm({
            title: "Reload Analytics Data.",
            type: "red",
            escapeKey: true,
            content: `Are you sure you want to reload all the Ananlytics data? This process might take up to <strong>${loadTime}</strong> minutes!`,
            theme: "bootstrap",
            icon: "fa fa-database",
            animation: "scale",
            closeAnimation: "scale",
            opacity: 0.5,
            container: "body",
            closeIcon: true,
            backgroundDismiss: true,
            columnClass: "col-md-8 col-md-offset-8",
            buttons: {
              confirm: {
                text: "Ok",
                btnClass: "btn-success",
                action: function () {
                  reloadVizData(count);
                },
              },
              Cancel: {
                btnClass: "btn-danger",
                keys: ["ctrl", "shift"],
              },
            },
          });
        })
        .catch((err) => {
          console.log(err);
        });
    });
  });

  $("#generate_data").on("click", function (e) {
    e.preventDefault();
    $.confirm({
      title: "Generate Analytics Data.",
      type: "red",
      escapeKey: true,
      content: `Are you sure you want to generate test data?`,
      theme: "bootstrap",
      icon: "fa fa-database",
      animation: "scale",
      closeAnimation: "scale",
      opacity: 0.5,
      container: "body",
      closeIcon: true,
      backgroundDismiss: true,
      columnClass: "col-md-8 col-md-offset-8",
      buttons: {
        confirm: {
          text: "Ok",
          btnClass: "btn-success",
          action: function () {
            // generates and downloads time tracking data
            generateRandomData(odsaStore, "csv")
              .then((resp) => {
                var blob = new Blob([resp["data"]], {
                  type: "text/plain",
                });
                const url = window.URL.createObjectURL(blob);
                const a = document.createElement("a");
                a.style.display = "none";
                a.href = url;
                // the filename you want
                a.download = `odsaTimeTrackingGeneratedData_${resp["date"]}.csv`;
                document.body.appendChild(a);
                a.click();
                window.URL.revokeObjectURL(url);
              })
              .catch((err) => {
                console.log(err);
              });
          },
        },
        Cancel: {
          btnClass: "btn-danger",
          keys: ["ctrl", "shift"],
        },
      },
    });
  });

  // var disc_diff_call = {
  //   url: "http://opendsa:8080/api/irtcurve/",
  //   method: "POST",
  //   timeout: 0,
  //   headers: {
  //     "Content-Type": "application/json",
  //   },
  //   data: JSON.stringify({
  //     bookID: ODSA_DATA.inst_book_id,
  //   }),
  // };
  // $.ajax(disc_diff_call).done(function (response) {
  //   console.log(response);
  // });

  // var parsed_response = JSON.parse(response);
  // var discriminationDifficultyArray = parsed_response.stdout_compressed

  // // var discriminationDifficultyArray = [
  // //   [1.1, 1.2],
  // //   [1.3, 1.4],
  // //   [1.5, 1.6],
  // // ];

  // discriminationDifficultyXAxis = [-4, -3, -2, -1, 0, 1, 2, 3, 4];
  // discriminationDifficultyYAxis = [];
  // var discriminationDifficultyData = [];

  // for (let i = 0; i < discriminationDifficultyArray.length; i++) {
  //   let discrimationDifficultyPair = discriminationDifficultyArray[i];

  //   let thisDiscriminationValue = discrimationDifficultyPair[0];
  //   let thisDifficultyValue = discrimationDifficultyPair[1];

  //   for (let j = -4; j <= 4; j++) {
  //     var discriminationDifficultyYAxisValue =
  //       1 /
  //       (1 +
  //         Math.pow(
  //           Math.E,
  //           -thisDiscriminationValue * (j - thisDifficultyValue)
  //         ));
  //     discriminationDifficultyYAxis.push(discriminationDifficultyYAxisValue);
  //   }

  //   var discriminationDifficultyGraph = {
  //     x: discriminationDifficultyXAxis,
  //     y: discriminationDifficultyYAxis,
  //     type: "scatter",
  //     name: `disrimination ${thisDiscriminationValue}, difficulty ${thisDifficultyValue}`,
  //   };

  //   discriminationDifficultyData.push(discriminationDifficultyGraph);
  //   Plotly.newPlot(
  //     "discriminationDifficultyGraph",
  //     discriminationDifficultyData
  //   );

  //   discriminationDifficultyYAxis = [];
  // }

  init();
});
