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


Demos
=====
There are several samples if you open the VidWorkspace. Also, check tags to find different demos in the commit history.

# GPU Quaternions performance tests
Tags: instanced-spheres-quaternions, instanced-sphere-matrices, instanced-cubes-quaternions, instanced-cubes-matrices, cubes-demo-quaternions, cubes-demo-matrices

Just examples of instancing and GPU quaternions. Read about it in detail in this blog post: http://tech.metail.com/performance-quaternions-gpu/

[![Instanced cubes](http://img.youtube.com/vi/Q7GQbFIXMJg/0.jpg)](https://www.youtube.com/watch?v=Q7GQbFIXMJg "Instanced cubes")

[![Instanced spheres](http://img.youtube.com/vi/P9fTjDLkOtI/0.jpg)](https://www.youtube.com/watch?v=P9fTjDLkOtI "Instanced cubes")


# Procedural 2D rain
Tag: rain-demo

Small example of using Metal in Swift. You can read about it in this blog post: http://tech.metail.com/metal-swift-introduction/
All the data updates happen in the GPU.

[![Procedural 2D rain](http://img.youtube.com/vi/7qWMA4ow2jc/0.jpg)](https://www.youtube.com/watch?v=7qWMA4ow2jc "Procedural 2D rain")


License
======
MIT License.
Please let me know if you use this in any of your projects.
