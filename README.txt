La carpeta combat_test tiene el contenido de godot del videojuego
Dentro de ella, GameState.gd contiene el string con el nivel que
se cargará. Ahora mismo, al ejecutar se da a Start, se generará el
 bosque, y si se da a continue se generará la cueva. Esto se debe 
al GameState, si se guardase la partida en el bosque, esto dejaría 
de funcionar y habría que toquetear el código para acceder a la cueva:
ir a scenes/main.gd y en la linea 4 poner el string del nivel al 
que se quiere ir, ejemplo:
var level = "cueva" , o var level = "bosque".

La carpeta Animations contiene las animaciones de los enemigos y
el jugador en formato .tres

La carpeta assets contiene assets de musica, imagenes y sonidos.

Dialogues contiene un archivo de prueba y el json con los diálogos

Scenes contiene todas las escenas, tanto las de bosque y las de cueva
en sus respectivas carpetas, con una estructura similar para que los
algoritmos generen las salas simplemente en función del nombre del nivel,
que coincidirá con el de una carpeta, y también escenar generales como
menu de pausa, escena principal, mapa, jugador, etc.

Scripts contiene scripts que se utilizan repetidas veces en muchas escenas,
como la gestión de barras de vida, hitboxes y hurtboxes, parrybox,
control de stamina, etc.