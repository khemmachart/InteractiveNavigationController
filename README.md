# InteractiveNavigationController
InteractiveNavigationController conforming to UINavigationControllerDelegate protocol that allows pan back gesture to be started from anywhere on the screen (not only from the left edge).<br>

### Prerequisites 
This project is written by Xcode9.3 and Swift4

### Installing

Copy these files to your project

```
InteractiveGestureRecognizer.swift
InteractiveNavigationController.swift
InteractivePopViewAnimator.swift
UIView+LeftSideShadow.swift
```

Then let your navigation controller class subblass InteractiveNavigationController, or use InteractiveNavigationController as a custom class for the UINavigationController

### Example results

![Alt text](https://cdn-images-1.medium.com/max/800/1*nOpkOfMs68McOHqcJDssAA.gif?raw=true "Interactive navigation controller")
![Alt text](https://cdn-images-1.medium.com/max/800/1*-CyKaN2Zan_PAiWmgFVnhw.gif?raw=true "Interactive navigation controller")
![Alt text](https://cdn-images-1.medium.com/max/800/1*AlL6p3O__wqCR1YLsyo7fg.gif?raw=true "Interactive navigation controller")

### Reference

This project is translated from SloppySwiper (Obj-c project) and also resolved the TabBar and NavigationBar bugs. You can get the original here. https://github.com/fastred/SloppySwiper
