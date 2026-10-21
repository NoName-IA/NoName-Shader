# HOLaa, este es mi shader ;p

como paso?-estaba en mi habitacion jugando cuando de repentre un shader que estaba usando 
presento tirones en la pantalla y se me crasheo el juego :v, entonces me dije a mi mismo:
porque no me hago un shader? y he aqui mi shader, inspirado en muchos de la comunidad, 
espero que disfrutes mucho este shader !! 
Todo el menú está en español.

![Atardecer sobre una aldea](fotos/superficie/atardecer-aldea.jpg)

---

## Galería

### Superficie

| | |
|---|---|
| ![Atardecer sobre una aldea](fotos/superficie/atardecer-aldea.jpg) | ![Atardecer sobre una mansión](fotos/superficie/atardecer-mansion.jpg) |
| **Atardecer** con el dramatismo del cielo y las casas iluminadas por dentro | Nubes 3D teñidas de rosa y violeta al caer el sol |
| ![La luna reflejada en el agua](fotos/superficie/luna-sobre-el-agua.jpg) | ![El sol entre la lluvia](fotos/superficie/sol-con-lluvia.jpg) |
| **Luna** con halo y su camino de luz sobre el agua | **Sol con lluvia**: pálido tras las nubes, con el suelo mojado reflejando la luz |
| ![Tormenta con relámpago](fotos/superficie/tormenta-relampago.jpg) | ![Cuevas vistas desde arriba](fotos/superficie/cuevas-desde-arriba.jpg) |
| **Tormenta**: nubes iluminadas por un relámpago | Cuevas con vegetación, lava y amatista |
| ![Cueva con minerales](fotos/superficie/cueva-con-minerales.jpg) | |
| **Minerales** con brillo propio y redstone en una cueva | |

### Interiores y sombras

| | |
|---|---|
| ![Sombras de ventanas en un pasillo](fotos/interiores/pasillo-sombras-de-ventanas.jpg) | ![Bloques de minerales y un faro](fotos/interiores/bloques-de-minerales-y-faro.jpg) |
| **Sombras** de las ventanas en el suelo y la pared, y vidrios tintados al fondo | **Bloques de minerales** pulidos y el rayo de un faro |
| ![Sala de estar](fotos/interiores/sala.jpg) | ![Baño de cuarzo](fotos/interiores/bano-de-cuarzo.jpg) |
| Interior iluminado con luz de bloques | Baño de **cuarzo** con su brillo pulido |

### Nether

| | |
|---|---|
| ![Mar de lava del Nether](fotos/nether/mar-de-lava.jpg) | ![Bosque distorsionado](fotos/nether/bosque-distorsionado.jpg) |
| Mar de lava con ondas de calor y el portal del Nether animado | Bosque distorsionado con su niebla verde azulada |

### End

| | |
|---|---|
| ![Portal del End](fotos/end/portal-del-end.jpg) | ![Isla del End con los cristales](fotos/end/isla-y-cristales.jpg) |
| **Portal del End** mostrando la isla del End al otro lado | La isla central con los rayos de los cristales del End |
| ![Dragón y pilares](fotos/end/dragon-y-pilares.jpg) | ![Ciudad del End](fotos/end/ciudad-del-end.jpg) |
| El dragón entre los pilares bajo el cielo con nebulosas | Una ciudad y un barco del End |
| ![Bosque de coros](fotos/end/bosque-de-coros.jpg) | |
| Flores de coro brillando de noche | |

---

## Requisitos

| | |
|---|---|
| Minecraft | 26.1.2 con **Fabric** |
| Mods | **Iris** 1.11.4 + **Sodium** (Fabric API) |
| Recomendado | Continuity (vidrio conectado), JourneyMap (sus balizas se ven brillantes) |
| Gráfica | Pensado para Intel o Ryzen  |

> No funciona con OptiFine: usa funciones propias de Iris (posición del barco, si vas montado, etc.).

## Instalación

1. Copia (o enlaza) la carpeta `NoName-Shader` dentro de `.minecraft\shaderpacks\`.
   En este PC ya está enlazada con un *junction*: `shaderpacks\NoName-Shader` → `Escritorio\NoName-Shader`, así que cualquier cambio en el escritorio se ve en el juego.
2. En el juego: *Opciones → Calidad de video → Shaders → NoName-Shader*.
3. Para recargar tras editar un archivo, pulsa **R** en el juego.

Tu configuración se guarda en `.minecraft\shaderpacks\NoName-Shader.txt`.

## Estructura

```
NoName-Shader/
├── README.md               este archivo
├── LICENSE                 licencia MIT
├── CHANGELOG.md            cambios de cada versión
├── fotos/                  capturas de la galería (superficie, interiores, nether, end)
└── shaders/
    ├── shaders.properties  menús, perfiles, uniforms propios (clima, biomas, amanecer...)
    ├── block.properties    IDs de bloques (agua, vidrio, minerales por material, portales...)
    ├── entity.properties   IDs de entidades (rayo, dragón, barcos, jugador)
    ├── item.properties     objetos que dan luz en la mano
    ├── dimension.properties
    ├── lang/               textos del menú (en_US.lang y es_ES.lang, ambos en español)
    ├── textures/           texturas del portal del End
    ├── world0/             Superficie   (aquí está casi todo lo propio)
    ├── world-1/            Nether
    ├── world1/             End
    └── world7/             Twilight Forest (mod)
```

Cada dimensión tiene sus programas (`gbuffers_*` dibujan bloques, agua, entidades, cielo...; `composite`, `composite1` y `final` son las pasadas a pantalla completa). Los cambios propios están marcados en el código con comentarios `//NoName:`.

## Perfiles de calidad

En la primera pantalla del menú, opción **Calidad**:

| Perfil | Para qué |
|---|---|
| **Bajo** | Máximos FPS: sin nubes, charcos, suelo mojado, brillo de minerales ni desenfoques. El agua se mantiene igual. |
| **Medio** | Equilibrado. Es la configuración de uso diario. |
| **Máximo** | Todo activado (sombras a máxima calidad, desenfoques, relieve del agua y de las nubes, estrellas, galaxias, hojas con viento, motion blur). Pesado. |

Si cambias cualquier opción a mano, el perfil aparece como *Custom*.

## Qué tiene

### Agua
- Agua transparente con color según la profundidad.
- El sol se refleja como un disco redondo, igual que en el cielo; la luna deja un **camino de luz** sobre el agua que solo aparece al mirarla.
- Agua vista a través de vidrio tintado con su color correcto.
- **Mar de tormenta** (*Agua → Mar de tormenta*): con tormenta el mar se vuelve gris verdoso y se levantan olas que se salen del bloque.
  - Tu barco sube, baja, cabecea y se ladea con la ola (tú también, en tercera persona), y el agua de alrededor se pega al casco.
  - Mobs y objetos que flotan en el mar suben y bajan con las olas.
  - Los huecos que dejan las olas altas (orillas, bajo el barco) se rellenan con agua.

### Cielo
- **Sol redondo** con halo suave; **luna** más grande (×1.3) con halo azulado según la fase.
- **Dramatismo del cielo**: atardeceres y amaneceres más intensos, con brillo rosa-violeta arriba.
- **Animación del amanecer**: destello en el horizonte cuando asoma el sol, sol rojizo y achatado que se aclara al subir, y deslumbramiento suave si lo miras de frente.
- **Sol con lluvia**: con lluvia normal el sol se ve pálido tras las nubes (con tormenta se oculta).
- **Nubes 3D** gruesas, con sombra propia, que se cierran rápido al empezar a llover y se abren al parar.
- **Destello de rayos**: el mundo parpadea cuando cae un rayo cerca.
- **Ambiente por bioma**: niebla verdosa en pantanos, calima cálida en desiertos, aire azulado en zonas frías.

### Clima
- **Charcos** que aparecen y desaparecen con la lluvia, reflejan el cielo y tienen ondas de gotas.
- **Suelo mojado**: una película de agua que refleja el cielo, el sol y las antorchas (casi sin brillo sobre césped y hojas).
- **Nieve acumulada** en la parte de arriba de bloques y hojas mientras nieva; se derrite despacio.
- Lluvia inclinada por el viento y plantas que se agitan más con tormenta.
- Las animaciones (viento, nubes...) siguen los ticks del juego (`/tick freeze` las congela); el agua sigue el tiempo real.

### Bloques y luz
- **Brillo de minerales** según el material real: metales con reflejo de su color, gemas con reflejo blanco, reflejo de la luna de noche y un pulso muy sutil en la redstone.
- **Brillo del cuarzo** (*Bloques → Brillo del cuarzo*): el cuarzo pulido refleja el cielo como el mármol, con un destello pequeño del sol, la luna y las antorchas.
- **Luz en la mano**: la antorcha y otros objetos luminosos (cubo de lava, vara de blaze, bayas luminosas, velas, linterna de redstone, ancla de reaparición...) iluminan alrededor, también en la otra mano.
- **Brillo de objetos en la mano** en primera persona.
- Portal del End que ilumina con sus colores el marco y las paredes; marcos vacíos con un parpadeo tenue.
- Portal del Nether animado.
- Rayos de faro y balizas de JourneyMap que brillan por sí solos.
- Mobs y jugadores se ven nítidos y bien iluminados aunque tengan agua o vidrio detrás.
- **Sombras** (*Ambiente → Sombras*, solo en el perfil Máximo): bloques, árboles, mobs y jugadores proyectan sombras del sol, a 4096 de resolución y hasta 128 bloques; la luz que pasa por vidrio tintado pinta el suelo de su color. Se suavizan con lluvia y desaparecen con el sol en el horizonte. El agua no proyecta sombra.

## Rendimiento

El shader está optimizado, refracción del agua con menos capas, niebla que solo se calcula donde se nota (y nada en cuevas), cielo simplificado en cuevas profundas, deslumbramiento del amanecer calculado una vez por frame y brillo del portal del End que solo trabaja si hay un portal cerca.

Lo que más pesa, por si hace falta ganar FPS: las **sombras** (dibujan el mundo dos veces; solo vienen en Máximo), las **nubes** (*Cielo → Nubes*), los **desenfoques** y la **distancia de renderizado** del juego.


## Créditos

Basado en el mi vision del minecraft, lol ;p

## Licencia

[MIT](LICENSE): puedes usar, copiar, modificar y compartir el shader libremente, siempre que mantengas el aviso de copyright.
