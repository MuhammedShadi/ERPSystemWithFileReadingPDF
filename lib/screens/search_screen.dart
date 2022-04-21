import 'package:flutter/material.dart';
import 'package:pdfviewer/models/discussion_item.dart';
import 'package:pdfviewer/providers/discussions_provider.dart';
import 'package:pdfviewer/screens/discussions_details.dart';

DiscussionsProvider _discussionsProvider = new DiscussionsProvider();
String searchImage = 'assets/images/search.png';

class SearchScreen extends StatefulWidget {
  static const routName = '/search';
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _searchController = new TextEditingController();
  bool themeSwitched = false;
  bool searchChecked = false;
  bool searchTextResult = false;
  var textValue = "";
  dynamic themeColor() {
    if (themeSwitched) {
      return Colors.grey[850];
    } else {}
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  _onSearchChanged() {
    setState(() {});
  }

  Widget chooseSearchBar = Center(
    child: Text(
      " بحث تفصيلي",
      style: TextStyle(fontFamily: 'Jazeera'),
    ),
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor(),
        elevation: 0,
        // ignore: deprecated_member_use
        brightness: themeSwitched ? Brightness.light : Brightness.dark,
        title: chooseSearchBar,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              Navigator.of(context).pushNamedAndRemoveUntil(
                  '/discussionsManagement', (Route<dynamic> route) => false);
            });
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: [
              Container(
                color: Colors.indigo.shade200,
                child: new Card(
                  child: new ListTile(
                    leading: new IconButton(
                      icon: new Icon(Icons.search),
                      onPressed: () {
                        setState(() {
                          searchTextResult = true;
                          searchChecked = false;
                          textValue = _searchController.text;
                          _searchController.clear();
                        });
                        // onSearchTextChanged('');
                      },
                    ),
                    title: new TextField(
                      controller: _searchController,
                      decoration: new InputDecoration(
                          hintText: 'بحث', border: InputBorder.none),
                      onTap: () {
                        //indexWedget();
                        setState(() {
                          // searchChecked = true;
                          searchTextResult = true;
                          getDiscussionsFilteredByTitle(_searchController.text);
                        });
                      },
                    ),
                    trailing: new IconButton(
                      icon: new Icon(Icons.cancel),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          searchChecked = false;
                          searchTextResult = false;
                        });
                        // onSearchTextChanged('');
                      },
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  searchTextResult == true || _searchController.text.isNotEmpty
                      ? SingleChildScrollView(
                          child: getDiscussionsFilteredByTitle(
                              _searchController.text))
                      : Column(
                          children: [
                            Text(
                              "لا توجد عناصر نتيجة البحث",
                              style: TextStyle(fontFamily: 'Jazeera'),
                            ),
                            Container(
                              child: Image.asset(
                                searchImage,
                                height: 420,
                                width: 420,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getDiscussionsFilteredByTitle(name) {
    return SingleChildScrollView(
      child: FutureBuilder(
          future: _discussionsProvider.getDiscussionsPFilteredByTitle(name),
          builder: (BuildContext context,
              AsyncSnapshot<List<DiscussionItem>> snapshot) {
            if (snapshot.data == null || snapshot.data.isEmpty) {
              return Center(
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 80),
                    child: Center(
                      child: Row(
                        children: <Widget>[
                          CircularProgressIndicator(),
                          SizedBox(
                            width: 20,
                          ),
                          Center(
                            child: Text(
                              "... من فضلك إنتظر يتم التحميل",
                              style: TextStyle(
                                fontFamily: 'Jazeera',
                                fontSize: 15,
                                color: themeSwitched
                                    ? Colors.white
                                    : Colors.indigo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            } else {
              return Scrollbar(
                // isAlwaysShown: true,
                child: Column(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height - 160,
                      child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: snapshot.data.length,
                          scrollDirection: Axis.vertical,
                          // ignore: missing_return
                          itemBuilder: (BuildContext context, int index) {
                            if (snapshot.hasData) {
                              return InkWell(
                                onTap: () {
                                  print(snapshot.data[index].id);
                                  Navigator.push(
                                    context,
                                    new MaterialPageRoute(
                                        builder: (context) =>
                                            DiscussionsDetails(
                                                snapshot.data[index].id)),
                                  );
                                },
                                child: Column(
                                  children: [
                                    new Card(
                                      color: Colors.red.shade50,
                                      margin: const EdgeInsets.only(
                                          left: 5.0,
                                          right: 5.0,
                                          bottom: 10.0,
                                          top: 3.0),
                                      elevation: 4.0,
                                      child: Column(
                                        children: [
                                          Row(
                                            children: <Widget>[
                                              Icon(
                                                Icons.comment,
                                                size: 35,
                                                color: themeSwitched
                                                    ? Colors.white
                                                    : Colors.redAccent,
                                              ),
                                              snapshot.data[index].files
                                                          .length ==
                                                      0
                                                  ? Row()
                                                  : Stack(
                                                      children: [
                                                        Icon(
                                                          Icons.attach_file,
                                                          size: 30,
                                                          color: themeSwitched
                                                              ? Colors.white
                                                              : Colors
                                                                  .redAccent,
                                                        ),
                                                        SizedBox(width: 35),
                                                        Positioned(
                                                          bottom: 0.0,
                                                          right: 0.0,
                                                          child: Text(
                                                            snapshot.data[index]
                                                                .files.length
                                                                .toString(),
                                                            style: TextStyle(
                                                              color: themeSwitched
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .redAccent,
                                                              fontFamily:
                                                                  'Jazeera',
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: <Widget>[
                                                    Row(
                                                      // mainAxisAlignment:
                                                      //     MainAxisAlignment.start,
                                                      children: <Widget>[
                                                        Expanded(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    right: 8.0),
                                                            child: Container(
                                                              child: Text(
                                                                snapshot
                                                                    .data[index]
                                                                    .name,
                                                                style:
                                                                    new TextStyle(
                                                                  color: themeSwitched
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black,
                                                                  fontFamily:
                                                                      'Jazeera',
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .end,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    right: 8.0),
                                                            child: Container(
                                                              child: Text(
                                                                snapshot
                                                                    .data[index]
                                                                    .author,
                                                                style:
                                                                    new TextStyle(
                                                                  color: themeSwitched
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black,
                                                                  fontFamily:
                                                                      'Jazeera',
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .end,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    right: 8.0),
                                                            child: Container(
                                                              child: Text(
                                                                snapshot.data[index].createdAt
                                                                            .split("T")[
                                                                        0] +
                                                                    '  ' +
                                                                    snapshot
                                                                        .data[
                                                                            index]
                                                                        .createdAt
                                                                        .split("T")[
                                                                            1]
                                                                        .split(
                                                                            '.')[0],
                                                                style:
                                                                    new TextStyle(
                                                                  color: themeSwitched
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black,
                                                                  fontFamily:
                                                                      'Jazeera',
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .end,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }),
                    ),
                  ],
                ),
              );
            }
          }),
    );
  }
}
