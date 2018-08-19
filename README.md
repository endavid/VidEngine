Vid Engine
=========
Graphics engine written in Metal & Swift.

It's an endless work-in-progress that I use in my spare to test things. It should be usable to do basic stuff, but note that there are no plans for OpenGL ES support, and thus, both older devices and the simulators are not supported. You will need a Metal-compatible iOS device to build and run it.

Installation
=========
Simply add this repository as a submodule in your repository. Then,

* Create a Workspace in Xcode
* Add your project to the workspace
* Add VidFramework project to the workspace.
* Select your project in Xcode, and in Target -> General -> Embedded Binaries, select VidFramework (it should appear if it's in your workspace). This should also add it to Linked Framework & Libraries. But if it doesn't, add it there as well. Also make sure it did add an entry in Build Phases -> Embed Frameworks.

Build
====
Use the provided build.sh, because I can't figure out how to get the shaders in VidMetalLib to get linked to the correct location from Xcode... 😅


Samples
=======
Open the VidWorkspace and you should see several samples.

## SampleAR

ARKit sample app using the VidEngine (WIP).

## SampleColorPalette

Example of using display-P3 color space, and Self-Organizing Maps (a type of neural network).

Read these blog posts:
* [Display P3 vs sRGB in Color Palettes](http://endavid.com/index.php?entry=80)
* [Exploring the display-P3 color space](http://endavid.com/index.php?entry=79)

Also, this sample has been expanded into a full app: [Palettist](http://palettist.endavid.com)

## SampleCornellBox

This is just the typical cornell box scene (WIP)

## SampleRain

Very simple procedural 2D rain. All the updates happen in the GPU with a compute shader.
You can read about it in this blog post: [Metal: a Swift Introduction](http://tech.metail.com/metal-swift-introduction/)

[![Procedural 2D rain](http://img.youtube.com/vi/7qWMA4ow2jc/0.jpg)](https://www.youtube.com/watch?v=7qWMA4ow2jc "Procedural 2D rain")

If you need a more minimalistic example, find the `rain-demo` tag in git history.

## SampleText

This demonstrates the support of font rendering in the 3D world using Signed-Distance Fields. 


## GPU Quaternions performance tests
You need to find these ones in the commit history.

Tags:

    instanced-spheres-quaternions
    instanced-sphere-matrices
    instanced-cubes-quaternions
    instanced-cubes-matrices
    cubes-demo-quaternions
    cubes-demo-matrices

Just examples of instancing and GPU quaternions. Read about it in detail in this blog post: 
[Performance of quaternions in the GPU](http://tech.metail.com/performance-quaternions-gpu/)

[![Instanced cubes](http://img.youtube.com/vi/Q7GQbFIXMJg/0.jpg)](https://www.youtube.com/watch?v=Q7GQbFIXMJg "Instanced cubes")

[![Instanced spheres](http://img.youtube.com/vi/P9fTjDLkOtI/0.jpg)](https://www.youtube.com/watch?v=P9fTjDLkOtI "Instanced cubes")


License
======
MIT License.
Please let me know if you use this in any of your projects.
