import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(CocktailApp());
}

class CocktailApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cocktail App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CocktailListScreen(),
    );
  }
}

class CocktailListScreen extends StatefulWidget {
  @override
  _CocktailListScreenState createState() => _CocktailListScreenState();
}

class _CocktailListScreenState extends State<CocktailListScreen> {
  List<Cocktail> cocktails = [];
  String sortField = 'name';
  int selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    DatabaseHelper.instance.checkCocktailTableAndDeleteInconsistentCocktails();
    loadCocktails();
  }

  Future<void> loadCocktails() async {
    List<Cocktail> loadedCocktails =
        await DatabaseHelper.instance.getCocktails();
    setState(() {
      cocktails = loadedCocktails;
    });
  }

  Future<void> addCocktail(Cocktail cocktail) async {
    print('addCocktail');
    await DatabaseHelper.instance.insertCocktail(cocktail);
    loadCocktails(); // Recharge la liste des cocktails après l'ajout
  }

  Future<void> updateCocktail(Cocktail cocktail) async {
    await DatabaseHelper.instance.updateCocktailById(cocktail);
    await loadCocktails();
  }

  Future<void> deleteCocktail(int id) async {
    await DatabaseHelper.instance.deleteCocktailById(id);
    await loadCocktails();
  }

  void sortCocktails(String field) {
    setState(() {
      sortField = field;
      if (field == 'ratingVal' || field == 'ratingAurel') {
        cocktails.sort((a, b) => b.compareTo(a, field));
      } else {
        cocktails.sort((a, b) => a.compareTo(b, field));
      }
    });
  }

  DecorationImage _getCocktailImage(String imagePath) {
    if (imagePath.isNotEmpty) {
      return DecorationImage(
        fit: BoxFit.cover,
        image: FileImage(File(imagePath)),
      );
    } else {
      return DecorationImage(
        fit: BoxFit.cover,
        image: AssetImage('assets/images/default_image.png'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des Cocktails'),
        actions: [
          if (selectedIndex != -1)
            IconButton(
              icon: Icon(Icons.fullscreen),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageScreen(
                      imagePath: cocktails[selectedIndex].imagePath,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Trier par:',
              style: TextStyle(fontSize: 18),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => sortCocktails('name'),
                child: Text('Nom'),
              ),
              ElevatedButton(
                onPressed: () => sortCocktails('location'),
                child: Text('Lieu'),
              ),
              ElevatedButton(
                onPressed: () => sortCocktails('ratingVal'),
                child: Text('Note Val'),
              ),
              ElevatedButton(
                onPressed: () => sortCocktails('ratingAurel'),
                child: Text('Note Aurel'),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cocktails.length,
              itemBuilder: (context, index) {
                String formattedDate =
                    DateFormat('dd/MM/yyyy').format(cocktails[index].date);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  child: Dismissible(
                    key: Key(cocktails[index].id.toString()),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (direction) async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('T\'es sûr?'),
                          content: const Text('Tu ne reverras peut-être JAMAIS ce coktail !'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () {
                                deleteCocktail(cocktails[index].id);
                                Navigator.pop(context, true);
                              },
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ),
                      );

                      if (result == null || !result) {
                        return;
                      }
                    },
                    background: Container(
                      color: Colors.red,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 60.0,
                        height: 60.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: _getCocktailImage(cocktails[index].imagePath),
                        ),
                      ),
                      title: Text(cocktails[index].name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lieu: ${cocktails[index].location?.titre}'),
                          Row(
                            children: [
                              Text('Val: '),
                              Icon(Icons.star,
                                  color: Colors.yellow, size: 16.0),
                              Text(
                                  '${cocktails[index].ratingVal.toStringAsFixed(1)}'),
                            ],
                          ),
                          Row(
                            children: [
                              Text('Aurel: '),
                              Icon(Icons.star,
                                  color: Colors.yellow, size: 16.0),
                              Text(
                                  '${cocktails[index].ratingAurel.toStringAsFixed(1)}'),
                            ],
                          ),
                          if (cocktails[index].comment.isNotEmpty)
                            Text('Commentaire: ${cocktails[index].comment}'),
                          Text('Date: $formattedDate'),
                        ],
                      ),
                      trailing: index == selectedIndex
                          ? Icon(Icons.check)
                          : IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditCocktailScreen(
                                      cocktail: cocktails[index],
                                      updateCocktail: updateCocktail,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Afficher un menu contextuel lorsque l'utilisateur appuie longuement sur le bouton flottant
          showMenu(
            context: context,
            position: RelativeRect.fromLTRB(
                100, 100, 0, 100), // Ajustez ces valeurs selon vos besoins
            items: [
              PopupMenuItem(
                child: ListTile(
                  leading: Icon(Icons.local_bar),
                  title: Text('Ajouter un Cocktail'),
                  onTap: () {
                    Navigator.pop(context); // Fermez le menu contextuel
                    // Naviguer vers l'écran d'ajout de cocktail
                    navigateToAddScreen(context);
                    /*Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddCocktailScreen(),
                      ),
                    );*/
                  },
                ),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text('Ajouter un Lieu'),
                  onTap: () {
                    Navigator.pop(context); // Fermez le menu contextuel
                    // Naviguer vers l'écran d'ajout de lieu
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateLieuScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void navigateToAddScreen(BuildContext context) async {
    Cocktail? newCocktail = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddCocktailScreen()),
    );
    print(newCocktail?.name);
    if (newCocktail != null) {
      await addCocktail(newCocktail);
    }
  }
}

class AddCocktailScreen extends StatefulWidget {
  @override
  _AddCocktailScreenState createState() => _AddCocktailScreenState();
}

class _AddCocktailScreenState extends State<AddCocktailScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController commentController = TextEditingController();
  Lieu? selectedLocation;
  double ratingVal = 0.0;
  double ratingAurel = 0.0;
  late File _image;
  List<Lieu> lieux = [];

  @override
  void initState() {
    super.initState();
    _image = File('');
    _loadLieuxFromDatabase();
  }

  Future<void> _loadLieuxFromDatabase() async {
    // Utilisez await pour appeler la méthode asynchrone
    List<Lieu> lieuxFromDatabase = await DatabaseHelper.instance.getAllLieux();
    setState(() {
      lieux = lieuxFromDatabase;
    });
    if (lieux.isNotEmpty) {
      setState(() {
        selectedLocation = lieux[0]; // Utilisez le premier lieu trouvé
      });
    }
  }

  Future<void> pickImage() async {
    final imagePicker = ImagePicker();
    final pickedImage =
        await imagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedImage != null) {
        _image = File(pickedImage.path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter un cocktail'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_image != null && _image.path.isNotEmpty)
                Image.file(
                  _image,
                  width: 200.0,
                  height: 200.0,
                  fit: BoxFit.cover,
                ),
              ElevatedButton(
                onPressed: pickImage,
                child: Text('Sélectionner une image'),
              ),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nom',
                ),
              ),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: 'Commentaire',
                ),
              ),
              DropdownButtonFormField<Lieu>(
                value: selectedLocation,
                onChanged: (Lieu? newValue) {
                  setState(() {
                    selectedLocation = newValue;
                  });
                },
                items: lieux.map((Lieu lieu) {
                  return DropdownMenuItem<Lieu>(
                    value: lieu,
                    child: Text(lieu.titre), // Utilisez le titre du Lieu
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Lieu',
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Note Val:',
                style: TextStyle(fontSize: 18),
              ),
              Slider(
                value: ratingVal,
                min: 0.0,
                max: 10.0,
                divisions: 20,
                onChanged: (value) {
                  setState(() {
                    ratingVal = value;
                  });
                },
                label: ratingVal.toStringAsFixed(1),
              ),
              SizedBox(height: 20),
              Text(
                'Note Aurel:',
                style: TextStyle(fontSize: 18),
              ),
              Slider(
                value: ratingAurel,
                min: 0.0,
                max: 10.0,
                divisions: 20,
                onChanged: (value) {
                  setState(() {
                    ratingAurel = value;
                  });
                },
                label: ratingAurel.toStringAsFixed(1),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  String name = nameController.text.trim();
                  String comment = commentController.text.trim();
                  if (name.isNotEmpty) {
                    DateTime now = DateTime.now();
                    Cocktail newCocktail = Cocktail(
                      name: name,
                      location: selectedLocation,
                      ratingVal: ratingVal,
                      ratingAurel: ratingAurel,
                      imagePath: _image.path,
                      comment: comment,
                      date: now,
                    );
                    Navigator.pop(context, newCocktail);
                  }
                },
                child: Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditCocktailScreen extends StatefulWidget {
  final Cocktail cocktail;
  final Function(Cocktail cocktail) updateCocktail;

  EditCocktailScreen({
    required this.cocktail,
    required this.updateCocktail,
  });

  @override
  _EditCocktailScreenState createState() => _EditCocktailScreenState();
}

class _EditCocktailScreenState extends State<EditCocktailScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController commentController = TextEditingController();
  Lieu? selectedLocation;
  double ratingVal = 0.0;
  double ratingAurel = 0.0;
  late File _image;
  List<Lieu> lieux = [];

  @override
  void initState() {
    super.initState();
    nameController.text = widget.cocktail.name;
    commentController.text = widget.cocktail.comment;
    selectedLocation = widget.cocktail.location;
    ratingVal = widget.cocktail.ratingVal;
    ratingAurel = widget.cocktail.ratingAurel;
    _image = File(widget.cocktail.imagePath);
    _loadLieuxFromDatabase();
  }

  Future<void> _loadLieuxFromDatabase() async {
    // Utilisez await pour appeler la méthode asynchrone
    List<Lieu> lieuxFromDatabase = await DatabaseHelper.instance.getAllLieux();
    setState(() {
      lieux = lieuxFromDatabase;
    });
    if (lieux.isNotEmpty) {
      setState(() {
        selectedLocation = lieux[0]; // Utilisez le premier lieu trouvé
      });
    }
  }

  Future<void> pickImage() async {
    final imagePicker = ImagePicker();
    final pickedImage =
        await imagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedImage != null) {
        _image = File(pickedImage.path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier un cocktail'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_image != null && _image.path.isNotEmpty)
                Image.file(
                  _image,
                  width: 200.0,
                  height: 200.0,
                  fit: BoxFit.cover,
                ),
              ElevatedButton(
                onPressed: pickImage,
                child: Text('Sélectionner une image'),
              ),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nom',
                ),
              ),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: 'Commentaire',
                ),
              ),
              DropdownButtonFormField<Lieu>(
                value: selectedLocation,
                onChanged: (Lieu? newValue) {
                  setState(() {
                    selectedLocation = newValue;
                  });
                },
                items: lieux.map((Lieu lieu) {
                  return DropdownMenuItem<Lieu>(
                    value: lieu,
                    child: Text(lieu.titre), // Utilisez le titre du Lieu
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Lieu',
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Note Val:',
                style: TextStyle(fontSize: 18),
              ),
              Slider(
                value: ratingVal,
                min: 0.0,
                max: 10.0,
                divisions: 20,
                onChanged: (value) {
                  setState(() {
                    ratingVal = value;
                  });
                },
                label: ratingVal.toStringAsFixed(1),
              ),
              SizedBox(height: 20),
              Text(
                'Note Aurel:',
                style: TextStyle(fontSize: 18),
              ),
              Slider(
                value: ratingAurel,
                min: 0.0,
                max: 10.0,
                divisions: 20,
                onChanged: (value) {
                  setState(() {
                    ratingAurel = value;
                  });
                },
                label: ratingAurel.toStringAsFixed(1),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  String name = nameController.text.trim();
                  String comment = commentController.text.trim();
                  if (name.isNotEmpty) {
                    Cocktail updatedCocktail = Cocktail(
                      id: widget.cocktail.id,
                      name: name,
                      location: selectedLocation,
                      ratingVal: ratingVal,
                      ratingAurel: ratingAurel,
                      imagePath: _image.path,
                      comment: comment,
                      date: widget.cocktail.date,
                    );
                    widget.updateCocktail(updatedCocktail);
                    Navigator.pop(context);
                  }
                },
                child: Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FullScreenImageScreen extends StatelessWidget {
  final String imagePath;

  FullScreenImageScreen({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Container(
          color: Colors.black,
          child: Center(
            child: Image.file(
              File(imagePath),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class Cocktail {
  int id;
  String name;
  Lieu? location; // Champ pour le lieu
  double ratingVal;
  double ratingAurel;
  String imagePath;
  String comment;
  DateTime date;

  Cocktail({
    this.id = 0,
    required this.name,
    required this.location,
    required this.ratingVal,
    required this.ratingAurel,
    required this.imagePath,
    required this.comment,
    required this.date,
  });

  Cocktail.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        location = Lieu.fromJson(json['location']), // Désérialisation du lieu,
        ratingVal = json['ratingVal'].toDouble(),
        ratingAurel = json['ratingAurel'].toDouble(),
        imagePath = json['imagePath'],
        comment = json['comment'],
        date = DateTime.parse(json['date']);

  factory Cocktail.fromMap(Map<String, dynamic> map, Lieu? lieu) {
    return Cocktail(
      id: map['id'],
      name: map['name'],
      location: lieu,
      ratingVal: map['ratingVal'],
      ratingAurel: map['ratingAurel'],
      imagePath: map['imagePath'],
      comment: map['comment'],
      date: DateTime.parse(map['date']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lieuId': location?.id, // Sérialisation du lieu,
        'location': location?.toJson(),
        'ratingVal': ratingVal,
        'ratingAurel': ratingAurel,
        'imagePath': imagePath,
        'comment': comment,
        'date': date.toIso8601String(),
      };

  int compareTo(Cocktail other, String field) {
    if (field == 'name') {
      return name.compareTo(other.name);
    } else if (field == 'location') {
      // Compare les lieux en tenant compte de la possibilité de null
      if (location == null && other.location == null) {
        return 0;
      } else if (location == null) {
        return -1; // Les éléments avec location null viennent avant
      } else if (other.location == null) {
        return 1; // Les éléments avec other.location null viennent avant
      } else {
        return location!.compareTo(other.location!);
      }
    } else if (field == 'ratingVal') {
      return ratingVal.compareTo(other.ratingVal);
    } else if (field == 'ratingAurel') {
      return ratingAurel.compareTo(other.ratingAurel);
    }
    return 0;
  }
}

class Lieu {
  int? id; // Identifiant unique du lieu
  String titre; // Titre du lieu

  Lieu({
    this.id,
    required this.titre,
  });

  factory Lieu.fromMap(Map<String, dynamic> map) {
    return Lieu(
      id: map['id'],
      titre: map['titre'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
    };
  }

  Map<String, dynamic> toJson() => {
        'title': titre,
      };

  factory Lieu.fromJson(Map<String, dynamic> json) {
    return Lieu(
      titre: json['title'],
    );
  }

  int compareTo(Lieu other) {
    return titre.compareTo(other.titre);
  }
}

class CreateLieuScreen extends StatefulWidget {
  @override
  _CreateLieuScreenState createState() => _CreateLieuScreenState();
}

class _CreateLieuScreenState extends State<CreateLieuScreen> {
  // Ajoutez les contrôleurs de texte pour chaque champ de saisie
  final TextEditingController _titreController = TextEditingController();

  // Méthode pour enregistrer le lieu dans la base de données
  _saveLieu() async {
    String titre = _titreController.text.trim();

    if (titre.isEmpty) {
      // Affichez une boîte de dialogue ou un message d'erreur si les champs sont vides.
      return;
    }

    // Créez un objet Lieu à partir des informations saisies
    Lieu lieu = Lieu(titre: titre);

    // Utilisez votre classe DatabaseHelper (ou équivalente) pour ajouter le lieu
    // dans la base de données.
    await DatabaseHelper.instance.insertLieu(lieu);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer un Lieu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _titreController,
              decoration: InputDecoration(
                labelText: 'Titre',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                String titre = _titreController.text.trim();
                if (titre.isNotEmpty) {
                  Lieu newLieu = Lieu(titre: titre);
                  _saveLieu();
                  Navigator.pop(context, newLieu);
                }
              },
              child: Text('Enregistrer'),
            ),

            // Ajoutez ici des champs de saisie pour les informations du lieu
            // Utilisez des TextFormField ou des TextField, par exemple.
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _saveLieu();
        },
        child: Icon(Icons.save),
      ),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._getInstance();
  static Database? _database;

  DatabaseHelper._getInstance();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'cocktail.db');

    return await openDatabase(
      path,
      version: 2, // Augmentez la version pour déclencher la migration
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase, // Ajoutez cette ligne pour la migration
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE lieux (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titre TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cocktails (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        lieuId INTEGER REFERENCES lieux(id),
        ratingVal REAL NOT NULL,
        ratingAurel REAL NOT NULL,
        imagePath TEXT NOT NULL,
        comment TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (lieuId) REFERENCES lieux(id)
      )
    ''');
  }

  // Méthode de mise à niveau de la base de données pour la migration
  Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    backupDatabase();
    if (oldVersion < 2) {
      // Vous pouvez ajouter des opérations de migration ici
      // Si vous avez besoin de copier des données de l'ancienne structure vers la nouvelle
      // Requête pour ajouter la table "lieux" à la base de données
      await db.execute('''
        CREATE TABLE lieux (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          titre TEXT NOT NULL
        );
      ''');

      await db.execute('''
        ALTER TABLE cocktails
        ADD COLUMN lieuId INTEGER REFERENCES lieux(id)
      ''');

      // Récupérez les cocktails existants
      final List<Map<String, dynamic>> cocktails = await db.query('cocktails');

      // Parcourez chaque cocktail pour obtenir son lieu actuel
      for (final cocktail in cocktails) {
        final String location = cocktail['location'] as String;

        // Vérifiez si le lieu existe déjà dans la table "lieux"
        final List<Map<String, dynamic>> existingLocations = await db.query(
          'lieux',
          where: 'titre = ?',
          whereArgs: [location],
        );

        int lieuId;

        // Si le lieu existe, utilisez son ID
        if (existingLocations.isNotEmpty) {
          lieuId = existingLocations.first['id'] as int;
        } else {
          // Si le lieu n'existe pas, ajoutez-le à la table "lieux"
          lieuId = await db.insert('lieux', {'titre': location});
        }

        // Mettez à jour le cocktail avec le lieuId correspondant
        await db.update(
          'cocktails',
          {'lieuId': lieuId},
          where: 'id = ?',
          whereArgs: [cocktail['id']],
        );
      }
    }
  }

  Future<void> backupDatabase() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String currentDBPath = join(appDir.path, 'cocktail.db');
      final String backupDBPath = join(appDir.path, 'cocktail_backup.db');

      // Copiez le fichier de base de données actuel vers le fichier de sauvegarde
      await File(currentDBPath).copy(backupDBPath);
      print('Base de données sauvegardée avec succès.');
    } catch (e) {
      print('Erreur lors de la sauvegarde de la base de données : $e');
    }
  }

  Future<void> checkCocktailTableAndDeleteInconsistentCocktails() async {
    final db = await database;
    final result = await db.query('cocktails');

    if (result.isNotEmpty) {
      print('Contenu de la table cocktails :');
      for (final row in result) {
        print('ID: ${row['id']}');
        print('Nom: ${row['name']}');
        print('Comment: ${row['comment']}');
        print(
            'Lieu ID: ${row['lieuId']}'); // Si lieuId est une colonne de la table.

        if (null == row['lieuId']) {
          print('deleteCocktail: ${row['id']}');
          deleteCocktailById(row['id'] as int);
        }
        // Ajoutez d'autres colonnes ici au besoin.
        print('------------------------');
      }
    } else {
      print('La table cocktails est vide.');
    }
  }

  Future<List<Cocktail>> getCocktails() async {
    Database db = await instance.database;

    final List<Map<String, dynamic>> maps = await db.query('cocktails',
        orderBy: 'ratingVal DESC, ratingAurel DESC');

    final cocktails = <Cocktail>[];

    for (final map in maps) {
      if (null != map['lieuId']) {
        final lieuId = map['lieuId'] as int;
        final lieu = await getLieuById(lieuId);
        final cocktail = Cocktail.fromMap(map, lieu);

        cocktails.add(cocktail);
      }
    }

    return cocktails;
  }

  Future<int> insertCocktail(Cocktail cocktail) async {
    print('Insert cocktail');
    Database db = await instance.database;
    int id = DateTime.now()
        .microsecondsSinceEpoch; // Génère un nouvel identifiant unique
    cocktail.id = id; // Assigne l'identifiant au cocktail
    print('lieu id: ${cocktail.location?.id}');
    print(cocktail.toJson());
    return await db.insert('cocktails', cocktail.toJson());
  }

  Future<void> updateCocktailById(Cocktail cocktail) async {
    Database db = await instance.database;
    await db.update(
      'cocktails',
      cocktail.toJson(),
      where: 'id = ?',
      whereArgs: [cocktail.id],
    );
  }

  Future<void> deleteCocktailById(int id) async {
    Database db = await instance.database;
    await db.delete(
      'cocktails',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Insérer un lieu dans la base de données
  Future<int> insertLieu(Lieu lieu) async {
    final db = await database;
    return await db.insert('lieux', lieu.toMap());
  }

  // Récupérer un lieu par son ID
  Future<Lieu?> getLieuById(int id) async {
    final db = await database;
    final maps = await db.query(
      'lieux',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Lieu.fromMap(maps.first);
    } else {
      return null;
    }
  }

  // Récupérer tous les lieux
  Future<List<Lieu>> getAllLieux() async {
    final db = await database;
    final maps = await db.query('lieux');
    return List.generate(maps.length, (i) {
      return Lieu.fromMap(maps[i]);
    });
  }

  // Mettre à jour un lieu
  Future<int> updateLieu(Lieu lieu) async {
    final db = await database;
    return await db.update(
      'lieux',
      lieu.toMap(),
      where: 'id = ?',
      whereArgs: [lieu.id],
    );
  }

  // Supprimer un lieu par son ID
  Future<int> deleteLieu(int id) async {
    final db = await database;
    return await db.delete(
      'lieux',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
