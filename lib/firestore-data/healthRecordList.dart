import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:unimec/model/HealthRecordProcessor.dart';
import 'package:unimec/model/userData.dart';

class HealthRecordList extends StatefulWidget {
  @override
  _HealthRecordListState createState() => _HealthRecordListState();
}

class _HealthRecordListState extends State<HealthRecordList> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<int, HealthRecordProcessor> recordProcs = {};
  late User user;
  late String _documentID;

  Future<void> _getUser() async {
    user = _auth.currentUser!;
  }

  String _dateFormatter(String timestamp) {
    String formattedDate =
        DateFormat('dd-MM-yyyy').format(DateTime.parse(timestamp));
    return formattedDate;
  }

  String _timeFormatter(String _timestamp) {
    String formattedTime =
        DateFormat('kk:mm').format(DateTime.parse(_timestamp));
    return formattedTime;
  }

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  var _test = false;

  // TODO: use for updating visibility of health record
  Future<void> createHiddenHealthRecordData(
      recordIndex,
      Map<String, dynamic> privateData,
      Map<String, dynamic> publicData,
      List<String> hiddenKeys) async {
    publicData["glucose"] = "110";
    publicData["heart_rate"] = "85";
    publicData["severe_condition"] = false;

    for (int i = 0; i < hiddenKeys.length; i++) {
      if (publicData.containsKey(hiddenKeys[i])) {
        privateData[hiddenKeys[i]] = publicData[hiddenKeys[i]];
        publicData.remove(hiddenKeys[i]);
      }
    }

    // encrypt private data
    var userData = UserData.getInstance();
    var encryptedData = await recordProcs[recordIndex]
        ?.createEncryptedData(privateData, userData.uid, userData.password);
    if (encryptedData == null || encryptedData.isEmpty) {
      print("[ERROR] Cannot hide data");
      return;
    }
    // print("encrypt data ${encryptedData}");
    // var secretData = recordProcs[recordIndex]?.parseEncryptedData(encryptedData, userData.uid, userData.password);
    // secretData?.then((value) {
    //   print("my key length ${value.keys.length}");
    //   for (var entry in value.entries) {
    //     print('${entry.key}: ${entry.value}');
    //   }
    // });

    // update to firestore
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('health_records')
          .doc("joNnLvAMQsWrRLIckf1P")
          .update({
        'public': publicData,
        'private': encryptedData,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating fields: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('health_records')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return snapshot.data?.size == 0
              ? Center(
                  child: Text(
                    'No Health Record',
                    style: GoogleFonts.lato(
                      color: Colors.grey,
                      fontSize: 18,
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.vertical,
                  physics: const ClampingScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: snapshot.data?.size,
                  itemBuilder: (context, index) {
                    // get user data
                    var userData = UserData.getInstance();

                    recordProcs[index] = HealthRecordProcessor(
                        snapshot.data?.docs[index] as DocumentSnapshot<Object?>,
                        userData.uid,
                        userData.password);

                    if (_test) {
                      // simulate: hide glucose, heart rate and severe condition
                      createHiddenHealthRecordData(
                          index,
                          {},
                          recordProcs[index]?.data["public"],
                          ["glucose", "heart_rate", "severe_condition"]);
                      _test = false;
                    }
                    // _test = true;

                    recordProcs[index]?.getHealthRecord();

                    return Card(
                      elevation: 2,
                      child: InkWell(
                        onTap: () {},
                        child: ExpansionTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: FutureBuilder(
                                  future: recordProcs[index]?.getHealthRecordDataByKey('doctor_name'),
                                  builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                    if (snapshot.connectionState == ConnectionState.done) {
                                      if (snapshot.hasData) {
                                        return Text(
                                          "Doctor: ${snapshot.data.toString()}",
                                          style: GoogleFonts.lato(
                                            fontSize: 16,
                                          ),
                                        );
                                      } else {
                                        return const Text('loading...');
                                      }
                                    } else {
                                      return const CircularProgressIndicator();
                                    }
                                  },),
                              ),
                              const SizedBox(
                                width: 0,
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child:
                            FutureBuilder(
                              future: recordProcs[index]?.getHealthRecordDataByKey('date'),
                              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                if (snapshot.connectionState == ConnectionState.done) {
                                  if (snapshot.hasData) {
                                    return Text(
                                      "${_dateFormatter(snapshot.data?.toDate().toString() ?? "")}",
                                      style: GoogleFonts.lato(
                                      ),
                                    );
                                  } else {
                                    return const Text('loading...');
                                  }
                                } else {
                                  return const CircularProgressIndicator();
                                }
                              },),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 20, right: 10, left: 16),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      FutureBuilder(
                                        future: recordProcs[index]?.getHealthRecordDataByKey('date'),
                                        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                          if (snapshot.connectionState == ConnectionState.done) {
                                            if (snapshot.hasData) {
                                              return Text(
                                                "Time: ${_timeFormatter(snapshot.data?.toDate().toString() ?? "")}",
                                                style: GoogleFonts.lato(
                                                  fontSize: 16,
                                                ),
                                              );
                                            } else {
                                              return const Text('loading...');
                                            }
                                          } else {
                                            return const CircularProgressIndicator();
                                          }
                                        },),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      FutureBuilder(
                                        future: recordProcs[index]?.getHealthRecordDataByKey('age'),
                                        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                          if (snapshot.connectionState == ConnectionState.done) {
                                            if (snapshot.hasData) {
                                              return Text(
                                                "Age: ${snapshot.data.toString()}",
                                                style: GoogleFonts.lato(
                                                  fontSize: 16,
                                                ),
                                              );
                                            } else {
                                              return const Text('loading...');
                                            }
                                          } else {
                                            return const CircularProgressIndicator();
                                          }
                                        },),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      FutureBuilder(
                                        future: recordProcs[index]?.getHealthRecordDataByKey('gender'),
                                        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                          if (snapshot.connectionState == ConnectionState.done) {
                                            if (snapshot.hasData) {
                                              return Text(
                                                "Gender: ${snapshot.data.toString()}",
                                                style: GoogleFonts.lato(
                                                  fontSize: 16,
                                                ),
                                              );
                                            } else {
                                              return const Text('loading...');
                                            }
                                          } else {
                                            return const CircularProgressIndicator();
                                          }
                                        },),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      FutureBuilder(
                                        future: recordProcs[index]?.getHealthRecordDataByKey('height'),
                                        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                          if (snapshot.connectionState == ConnectionState.done) {
                                            if (snapshot.hasData) {
                                              return Text(
                                                "Height: ${snapshot.data.toString()}",
                                                style: GoogleFonts.lato(
                                                  fontSize: 16,
                                                ),
                                              );
                                            } else {
                                              return const Text('loading...');
                                            }
                                          } else {
                                            return const CircularProgressIndicator();
                                          }
                                        },),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      FutureBuilder(
                                        future: recordProcs[index]?.getHealthRecordDataByKey('weight'),
                                        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                          if (snapshot.connectionState == ConnectionState.done) {
                                            if (snapshot.hasData) {
                                              return Text(
                                                "Weight: ${snapshot.data.toString()}",
                                                style: GoogleFonts.lato(
                                                  fontSize: 16,
                                                ),
                                              );
                                            } else {
                                              return const Text('loading...');
                                            }
                                          } else {
                                            return const CircularProgressIndicator();
                                          }
                                        },),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      FutureBuilder(
                                        future: recordProcs[index]?.getHealthRecordDataByKey('glucose'),
                                        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                          if (snapshot.connectionState == ConnectionState.done) {
                                            if (snapshot.hasData) {
                                              return Text(
                                                "Glucose: ${snapshot.data.toString()}",
                                                style: GoogleFonts.lato(
                                                  fontSize: 16,
                                                ),
                                              );
                                            } else {
                                              return const Text('loading...');
                                            }
                                          } else {
                                            return const CircularProgressIndicator();
                                          }
                                        },),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      FutureBuilder(
                                        future: recordProcs[index]?.getHealthRecordDataByKey('heart_rate'),
                                        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                          if (snapshot.connectionState == ConnectionState.done) {
                                            if (snapshot.hasData) {
                                              return Text(
                                                "Heart Rate: ${snapshot.data.toString()}",
                                                style: GoogleFonts.lato(
                                                  fontSize: 16,
                                                ),
                                              );
                                            } else {
                                              return const Text('loading...');
                                            }
                                          } else {
                                            return const CircularProgressIndicator();
                                          }
                                        },),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      FutureBuilder(
                                        future: recordProcs[index]?.getHealthRecordDataByKey('severe_condition'),
                                        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                          if (snapshot.connectionState == ConnectionState.done) {
                                            if (snapshot.hasData) {
                                              return Text(
                                                "Severe Condition: ${snapshot.data.toString()}",
                                                style: GoogleFonts.lato(
                                                  fontSize: 16,
                                                ),
                                              );
                                            } else {
                                              return const Text('loading...');
                                            }
                                          } else {
                                            return const CircularProgressIndicator();
                                          }
                                        },),
                                      const SizedBox(
                                        height: 10,
                                      ),

                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
        },
      ),
    );
  }
}
