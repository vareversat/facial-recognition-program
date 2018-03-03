#pas fct


clc
clear all
close all

%Variabale global qui contiendra l'image sélectionnée par l'utilisateur
persistent choosenImage;
%Variabale globale qui contiendra les images sélectionnées par l'utilisateur
persistent listChoosenImage;
%Variabale globale qui contiendra le type de reconnaissance sélectionné par l'utilisateur
persistent recognitionType;
%Variable globale qui contiendra la base de donnée des images
persistent BDD;
%Variable globale contenant le visage moyen
persistent averageFace;



#Permet de vérifier si une image est est niveau de gris
#Paramètre : matrice de l'image à tester
#Retourne true si vrai en niveau de gris, false si en RGB
function result = isGrey(mat)
  result = 0;
  [h , l, n] = size(mat);
  if n == 1
    result = true;
  else
    result = false;
  endif
endfunction



#Permet de transformer la matrice d'une image en matrice colonne
#Paramètre : matrice à transormer
#Retourne la matrice colonne de l'image
function I = IToVector(mat)
  if(isGrey(mat) == 1)
    I = reshape(mat', size(mat, 1)*size(mat, 2), 1);
  else
    I = reshape(RGB2Grey(mat)', size(RGB2Grey(mat), 1)*size(RGB2Grey(mat), 2), 1);  
  end
endfunction



#Permet de transformer la matrice colonne d'une image en sa matrice originelle
#Paramètres : imageMat = matrice colonne; formerSize = taille originelle
#Retourne la matrice originelle
function M = VectorToI(imageMat, formerSize)
  M = reshape(imageMat, size(imageMat,1)/formerSize, size(imageMat,2)*formerSize);
  M = M';
endfunction



#Permet de transformer une image RVB en une image niveau de gris
#Paramètre : matrice de l'image RVB
#Retourne : matrice de l'image en niveau de gris
function mat = RGB2Grey(matriceRGB)
  mat(:, :) = round(0.3*matriceRGB(:, :, 1) + 0.59*matriceRGB(:, :, 2) + 0.11*matriceRGB(:, :, 3));

endfunction



#Permet de calculer le visage moyen à partir de tous les visages de la base de données.
#Retourne : La matrice du visage moyen
function moy = averageFaces(BDD)
  moy = mean(BDD, 2);
endfunction




#Permet de calculer la norme entre 2 vecteurs.
#Paramètres : v1 : Vecteur numéro 1 ; v2 : Vecteur numéro 2
#Retourn : la norme
function norm =  distance(v1, v2)

  col1 = IToVector(double(v1));
  col2 = IToVector(double(v2));
  norm = norm(col1 - col2);

endfunction


#Permet de comparer la fonction de densité des histogrammes de 2 images
#Retourne : La différence
function diff = compareDensityFunctionHist(image1 , image2)

  [NN1, XX1] = hist(image1(:), 20);
  [NN2, XX2] = hist(image2(:), 20);
  
  
  diff = sum(NN1.*log(NN1./NN2));

endfunction





#Permet de charger tous les visages de la base de données dans un tableau
#Chaque varième est la matrice colonne de la varième image
#Retourne : Retourne la la matrice comportante toutes les images
function M = loadBDD()

  %Création d'une matrice vide (pleine de zéros)
  M = zeros(128^2, 50);
  %Les zéros son remplacées avec les matrices colonnes de chaque images de la base de donnnée
  for var = 1:1:50
    face = '/home/valentin/Documents/cours2017-2018/P2/MODELISATION/Image/BDD/test';
    face = strcat(face,num2str(var),'.gif');
    matFace = imread(face);
    M(:, var) = IToVector(matFace);      
  endfor
  
    
endfunction



################METHODE DES HISTOGRAMMES


#Permet de de trouver les visages les plus proches de R dans la BDD M avec la méthode des histogrammes
#Paramètres : R = Image requête, M = La BDD, number = le nombre d'image les plus proches que l'on souhaite ajouter
#Retourne : les indexes des images les plus proches
function indexes = histogram(R, number)
  global BDD;
  global averageFace
  %Si l'image n'est pas en niveau de gris on la transforme en niveau de gris
  if (!isGrey(R))
    R = RGB2Grey(R);    
  endif
  
  %On soustrait d'abord le visage au visage requête
  difference = double(R) - double(VectorToI(averageFace, 128));
  %On appel la fonction de comparaison
  indexes = getClosestIndexesHIST(difference, BDD, number);

endfunction



#Permet d'obtenir les indexs des images les plus proches
#Retourne : un tableau contenant les index des images les plus proches
function closestFacesIndex = getClosestIndexesHIST(R, M, number)
  %On récupère le tableau trié des distances avec la méthodes des histogrammes
  [sortedArray, previousPosition] = sort(compareHIST(R, M), 1);
  %previousPosition nous donne la position avant le trie, et donc le numéro des images les plus proches
  closestFacesIndex = previousPosition(1:number);

endfunction



#Permet de comparer la matrice d'un visage avec chacune des images de la base de données auquelle on a enlevé le visage moyen avec la méthode des histogrammes
#Retourne : Une liste comportant toutes les distances entre chaque images et l'image requête
function tab = compareHIST(R, M)
  global averageFace;
  %Création d'un tableau vide (avec que des zéros)
  tab = zeros(50, 1);
  %Récupération du visage moyen
  avg = double(averageFace);
   
  for var = 1:1:size(M, 2)
    %On soustrait à chaque visage de la base le visage moyen
    M(:, var) = double(M(:, var)) - avg;
    %On ajoute dans le tableau chaque distance
    tab(var, 1) = compareDensityFunctionHist(R, VectorToI(M(:, var), 128));   
  endfor
  
endfunction


#############################





#############################METHODE D'EUCLIDE


#Permet de de trouver les visages les plus proches de R dans la BDD M avec la méthode de la distance euclidienne
#Paramètres : R = Image requête, M = La BDD, number = le nombre d'image les plus proches que l'on souhaite ajouter
#Retourne : les indexes des images les plus proches
function indexes = euclidianDistance(R, number)
  global BDD;
  global averageFace;
  %Si l'image n'est pas en niveau de gris on la transforme en niveau de gris
  if (!isGrey(R))
    R = RGB2Grey(R);    
  endif
  
  %On soustrait d'abord le visage au visage requête
  difference = double(R) - double(VectorToI(averageFace, 128));
  %On appel la fonction de comparaison
  indexes = getClosestIndexesEUCL(difference, BDD, number);
endfunction


#Permet d'obtenir les indexs des images les plus proches
#Retourne : un tableau contenant les index des images les plus proches
function closestFacesIndex = getClosestIndexesEUCL(R, M, number)

  %On récupère le tableau trié des distances avec la méthodes des histogrammes
  [sortedArray, previousPosition] = sort(compareEUCL(R, M), 1);
  %previousPosition nous donne la position avant le trie, et donc le numéro des images les plus proches
  closestFacesIndex = previousPosition(1:number);

endfunction




#Permet de comparer la matrice d'un visage avec chacune des images de la base de données auquelle on a enlevé le visage moyen avec la méthode d'euclide
#Retourne : Une liste comportant toutes les distances entre chaque images et l'image requête
function tab = compareEUCL(R, M)
  global averageFace;
  %Création d'un tableau vide (avec que des zéros)
  tab = zeros(50, 1);
  %Récupération du visage moyen
  avg = double(averageFace);
  
  for var = 1:1:size(M, 2)
  %On soustrait à chaque visage de la base le visage moyen
    M(:, var) = double(M(:, var)) - avg;
    %On ajoute dans le tableau chaque distance
    tab(var, 1) = distance(R, VectorToI(M(:, var), 128));    
  endfor
  
endfunction


###################################



#Affiche plusieurs images sur la même fenêtreelayout
#Paramètres : indexes = les indexs des images à afficher, image = l'image qui est comparée, number = le nombre d'image afficher
function multipleDisplay(indexes, image, number)
  %Calcul du nombre de lignes nécessaires pour subplot (ceil : le plus petit entier qui est supérieur au nombre donné)
  rowNumber = ceil(number/5);
  %Ce tableau contiendra les positions pour l'image principale
  mainIndexes = [];
  
  %On rempli ce tableau (explication dans la doc)
  for var2 = 0:5:rowNumber*5-1
    mainIndexes = [mainIndexes 1+var2 2+var2 3+var2];
  endfor
  %Affichage de l'image principale
  subplot(rowNumber*2 ,5, mainIndexes), imshow(image);
  %Cette constante dicte où sera placée chaque images (explication dans la doc)
  cst = (floor((number-1)/5))*5 + 5;
  %Remplissage du subplot avec les images qui ont les index dans le tableau "indexes"
  for var = 1:1:size(indexes, 1)
    subplot(rowNumber*2,5,var+cst), imshow(imread(strcat('/home/valentin/Documents/cours2017-2018/P2/MODELISATION/Image/BDD/test',num2str(indexes(var)),'.gif'))), title(num2str(indexes(var)));
  
  endfor    
  
endfunction





function window ()
  global BDD;
  global averageFace;
  
  BDD = loadBDD();
  averageFace = averageFaces(BDD);
  
  size = get (0, "screensize");
  height = 500;
  width = 1000;

  MainFrm = figure ( ...
    %Centrage de la fenêtre
    'position', [size(3)/2 - height, size(4)/2 - height/2, width, height], ...
    'name', 'Main window' ); 
    
   
  #Bouton pour importer le visage
  ImportButton = uicontrol (MainFrm, ... 
    'style',    'pushbutton', ... 
    'string',   'Import', ...
    'units',    'normalized', ...
    'position', [0.85, 0.55, 0.1, 0.07], ...
    'callback', { @importImage});
    
  #Label titre
  TitleLabel = uicontrol (MainFrm, ... 
    'style',    'text', ... 
    'string',   'FACE RECOGNITION', ...
    'units',    'normalized', ...
    'position', [0.75, 0.9, 0.18, 0.1]);    
    
  #Label du choix de nombre de visage à afficher
  QuestionLabel = uicontrol (MainFrm, ... 
    'style',    'text', ... 
    'string',   'How many faces ?', ...
    'units',    'normalized', ...
    'position', [0.83, 0.75, 0.15, 0.05]);    
  
  #TextBox pour entrer le nombre de visages en sortie
  NumberTextBox = uicontrol (MainFrm, ... 
    'style',    'edit', ... 
    'units',    'normalized', ...
    'position', [0.85, 0.68, 0.1, 0.05]);
    
  #Choix entre la méthode des histogrammes ou de la norme
  ChoicePopUpMenu = uicontrol(MainFrm, 
    'style','popupmenu', ...
    'string',{'Histograms','Euclidian distance'}, ...
    'units',    'normalized', ...
    'position', [0.7, 0.68, 0.1, 0.05], ...
    'callback', { @chooseRecognitionMethod, NumberTextBox});
    
  #Bouton pour lancer la reconnaissance
  StartButton = uicontrol (MainFrm, ... 
    'style',    'pushbutton', ... 
    'string',   'Start', ...
    'units',    'normalized', ...
    'position', [0.7, 0.55, 0.1, 0.07], ...
    'callback', { @startRecognition, NumberTextBox});
    
    
  #Bouton pour afficher l'historique
  HistoryButton = uicontrol (MainFrm, ... 
    'style',    'pushbutton', ... 
    'string',   'History', ...
    'units',    'normalized', ...
    'position', [0.7, 0.80, 0.1, 0.07], ...
    'callback', { @displayHistory});
end




#Ouvre l'explorateur de fichiers pour choisir une image à comparer
function importImage (hObject, eventdata)
  %Variable global qui contiendra le chemin de l'image choisie
  global choosenImage;
  global listChoosenImage;
  
  %Création d'un subplot vide pour réinit l'affichage
  subplot(3,5,[1 15])
  %Ouverture de l'explorateur de fichiers
  [fname, fpath] = uigetfile();
  %Lecture de l'image sélectionnée
  Img = imread (fullfile(fpath, fname));
  %Mise dans la variable globale
  choosenImage = fullfile(fpath, fname);
  %Sauvegarde des images sélectionnées
  listChoosenImage = [listChoosenImage ; choosenImage];
  %Affichage en grand de l'image
  subplot(1,5,[1 3]), imshow(Img);
  
end


#Lance la reconnaissance
function startRecognition (hObject, eventdata, TextBoxFrm, ChoicePopUpMenu)
  %Variable globale de l'image sélectionnée
  global choosenImage;
  global recognitionType;
  
 
  %Création d'un subplot vide pour réinit l'affichage
  subplot(3,5,[1 15])
  %Get du nombre de visage à afficher
  howMany = str2num(get(TextBoxFrm,'string'));
  
  %1 correspond à l'histogramme
  if (recognitionType == 1)
    %Récupération des indexs
    indexes = histogram(imread(choosenImage), howMany);
    %Affichage
    multipleDisplay(indexes, imread(choosenImage), howMany);
  endif
  
  %2 correspond à euclide
  if (recognitionType == 2)
    %Récupération des indexs
    indexes = euclidianDistance(imread(choosenImage), howMany);
    %Affichage
    multipleDisplay(indexes, imread(choosenImage), howMany);
  endif
  
end


#Selection et enregistre le type re reconnaissance choisi
function chooseRecognitionMethod (hObject, eventdata, TextBoxFrm, ImgFrmCompared)
  global recognitionType;
  %Remplissage de la variable globale avec le type re reconnaissance
  recognitionType = get(hObject,'value');
end


#Permet d'afficher l'historique des reconnaissances
function displayHistory (hObject, eventdata)
  %Liste comportant les images déjà comparées
  global listChoosenImage;
  
  %Subplot vide pour reinit la fenêtre
  subplot(3,5,[1 15])
  %Même principe que pour l'affichage principal (voir doc)
  mainIndexes = [];
  %Get le nombre de lignes
  rowNumber = ceil(size(listChoosenImage,1)/3);
  %Création du tablea des indexs
  for var2 = 0:5:rowNumber*5-1
    mainIndexes = [mainIndexes 1+var2 2+var2 3+var2]
  endfor 
  %Affichage
  for var = 1:1:size(listChoosenImage, 1)
    subplot(rowNumber,5,mainIndexes(var)), imshow(imread(listChoosenImage(var, :))), title(var);
  
  endfor  
  
end



#Lancement de l'interface graphique
window()



