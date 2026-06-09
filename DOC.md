# Second Brain Project
Tengo un directorio con cientos de notas semi-organizadas por carpetas y tags muy mejorables.

Actualmente lo manejo con Obsidian, pero quiero pasar a algo mas ligero. Estoy abierto a cualquier cambio, prefiriendo algo muy configurable y ligero a la vez. Me gusta mantener archivos que puedo leer con otros programas para poder usar scripts con su contenido.

No quiero aplicaciones electrum ni nada pesado. Adoro las TUI, uso zellij y zsh a diario, si conseguimos pulir una configuracion adaptada a mi modo de entender creo que una opcion ideal. Manejo helix usualmente, vim en algun servidor, no me importa aprender emacs si no fuera provechoso y no muy dificil para lo que quiero hacer.


## Estado actual
### Carpetas
- Projects, Important: intento de manejo de tareas integrando obsidian tasks, caldav, taskwarrior mediante los scripts de @/home/huan/Scripts/utilities/tiddlywiki/db_md_crear.py @/home/huan/Scripts/utilities/cron/mfuz_to_md.py @/home/huan/Scripts/utilities/cron/sync_vdir.sh @/home/huan/Scripts/utilities/cron/scripts_to_md.py

- Journals: Diario, controlado por script para añadir archivos modificados en ese dia, tareas completadas o creadas ... muy mejorables ya que la integracion con caldav, fuente de verdad de tareas es muy pobre.

- plantillas: plantillas para obsidian, muy usadas en mi config actual. me resultan muy comodas

- calendars: necesario para las integraciones, sin uso directo

- Adjuntos, Excalidraw o Dibujos:  explicaciones visuales asociadas a algun archivo


#### Spaces
carpetas dentro de la carpeta Spaces
- Blogs: Contenido usado en diferentes webs que usan hugo y archivos markdown
- Wiki: Fuente de notas secondbrain, algunas usadas en posts de blogs.
- Wiki/Markor: Fuente de notas personales desde el movil
- Linux: Fuente de notas informaticas centradas en el SO linux y apps del mismo
- alpine: idem del anterior
- nix: idem
- comandos: notas usualmente cortas sobre apps y flags usuales
- tutoriales: procesos largos realizados en algun servidor, ideal para recordar o reproducir
- notas: random
- python: notas tomadas al inicio de aprender python, falta mucho por añadir

### Tags
Algo relacioado con las carpetas, pero poco

## Otras fuentes de conocimiento
Uso diversas apps para lecturas:
- Freshrss
- Wallabag

Adoro la musica y mucho de lo que escribo o leo tiene relacion, asi que uso
- audiobookshelf: en un docker en un servidor pepecono
- airsonic: en pepecono

Para cine uso:
- kodi
- plex

Otras tecnologias|apps
- awesomewm en pc principal, windows en otra particion para juegos.
- proxmox para pruebas en otro pc
- pihole
- docker
- swag con certificados para dominio local con dns challenge
- homeassitant
- grafana
- atuin
- atuin scripts
- zellij
- telegram bots (buscador de conciertos en ticketmaster, notificador discos muspy, logger de otros bots, script runner con algun atajo|alias y logger de scripts manuales usando alias, info sobre musica personal) la mayoria estan en el servidor aunque se pueden ver /home/huan/gits/pollo/bot_conciertos o /home/huan/gits/pollo/bot_infomusic
- radicale como calendario y tareas y contactos fuente de verdad

Tengo multiples scripts varios en ~/Scripts y proyectos a medias en ~/gits/pollo, algunos los explico mas adelante.

Tengo varias web apps creadas por mi. Las rutas a los proyectos son:
- mihitas y notas, clones con diferentes temas hugo para las notas. uso un script para publicar en /home/huan/Scripts/menus/mihitas

##### Entrada de musica
- rss embeds: recopilatorio de videos de mis feeds de rss seleccionados. reside en /home/huan/gits/freshrss_embeeds

- bandcamp embeds: similar pero para mails imap en thunderbird que ordeno por carpetas con reglas de thunderbird. /home/huan/gits/bandcamp_imap_mails

- escuchowsky: generos musicales en un tree con videos de ejemplos para los mismos.  /home/huan/gits/pollo/escuchowsky

- tumtumpa: permite buscar recomendaciones de musica usando los scrobbles de varios usuarios de lastfm o listenbrainz /home/huan/gits/pollo/escuchowsy

- mustlisten: compara tus scrobbles con listas curadas de musica. /home/huan/gits/pollo/escuchowsky

- trasvase: para pasar musica de mi nas a mi pc. /home/huan/gits/pollo/trasvase

##### Herramientas varias
- log de discos apreciados: en pepecono. con un hotkey lanzo unos scripts en /home/huan/Scripts/Musica/blog/vvmm

- log de escucha de discos comprados usando caldav y lastfm con /home/huan/gits/pollo/dieta_sonora

- podcast: paso articulos a audio con TTS en /home/huan/gits/pollo/wallabag_to_mp3

- music-fuzzy: qt python app con multiples usos alrededor de una base de datos musical con multiple informacion de mi musica desde mb, lastfm, discogs, equipboard, whosampled, feeds, ... integrada con muspy, antiguamente spotify (tengo que borrarlo). Sigo usandola a diario pero es muy mejorable.

- discos nuevos: agrega discos a mi calendario caldav segun muspy /home/huan/gits/pollo/discos_nuevos

#### Proyectos no terminados
- Ensayos: Enciclopedia musical recopilando informacion de podcasts. /home/huan/gits/pollo/ensayos-musicales. Editor web incluido

- mix rater: valorando mis canciones preferidas para intentar crear un recomendador. /home/huan/gits/pollo/mix_rater
