# How are Planets were simulated
Jiro Mizuno
## Procedural Generation
- Used UV mapping
- Used perlin noise and multifractal noise

Source:
Texturing and Modeling: A Procedural Approach ed. 3 (Chapter 15)

<img src="imglog/moon.jpg" width="400" height="400">
<img src="imglog/venus.jpg" width="400" height="400">
<img src="imglog/earth.jpg" width="400" height="400">

## Earth
### Creating oceans
<img src="imglog/bareearth.png" width="400" height="200">

### Ice caps (hiding uv map distortions)
<img src="imglog/icecaps.png" width="400" height="200">

### Varying climate by altitude(noise)
<img src="imglog/establishingclimates.png" width="400" height="200">

### Muddling land texture with multifractals
<img src="imglog/climatization.png" width="400" height="200">

### Unsmoothening the ice caps
<img src="imglog/rattled.png" width="400" height="200">

### Adding rivers/lakes
<img src="imglog/final.png" width="400" height="200">

## Gas Giants
**Coriolis Effect**
- Responsible for circular cloud pattern in gas giants + earth

- Can be simulated by rotating perlin noise by the distance from (0,0) on the UV map.

<img src="imglog/gas.png" width="400" height="200">

## Coriolis Issues
- My perlin noise is not tileable
- Mitigated a bit by the moving gas constantly
- Assigning a different coriolis focus point for half the map to make it look more pleasant

## Rocky planets (moon)
### Basic moon highland v maria(lunar lowlands)

<img src="imglog/moonnormal.png" width="400" height="200">

### Adding crater ring

<img src="imglog/mooncrater.png" width="400" height="200">

### Adding crater rays

<img src="imglog/moonrays.png" width="400" height="200">

### Adding depth to crater via noise turbulence

<img src="imglog/finalmoon.png" width="400" height="200">
