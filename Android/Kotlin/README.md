# Kotlin based samples

## Domain
This folder contains [Use cases](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html) from domain layer. [GetFriendsUseCase](domain/GetFriendsUseCase.kt) fetches data by social network api. [FriendsPresenter](domain/FriendsPresenter.kt) controls the data flow usages.

### Files

* [SingleUseCase.kt](domain/SingleUseCase.kt)
* [GetFriendsUseCase.kt](domain/GetFriendsUseCase.kt)
* [FriendsPresenter.kt](domain/FriendsPresenter.kt)

## Custom view behavior
This folder contains a simple UI sample of an[App bar](https://developer.android.com/training/appbar/) with the attached [circle button](https://developer.android.com/guide/topics/ui/floating-action-button).

<img src="https://media.giphy.com/media/fGFLqXr1ECaemooswt/giphy.gif" />

### Files

* [activity_main.xml](custom_view_behavior/activity_main.xml)
* [CustomFabBehavior.kt](custom_view_behavior/CustomFabBehavior.kt)
* [MainActivity.kt](custom_view_behavior/MainActivity.kt)