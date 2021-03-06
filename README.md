# Amaretto

Amaretto is a framework and a boilerplate to create OSX apps using HTML5/JavaScript that interact with native code.

An Amaretto-based application is just a window with a Web View. Amaretto provides a set of API that allow bi-directional communication between JavaScript and the native application.<br />
When you create your application with Amaretto, you are free to build your own HTML5 app using any style and any framework you prefer.

Amaretto is extremely lightweight. Unlike solutions that bundle Node.js or WebKit, Amaretto uses a normal Web View and frameworks shipped with OSX.<br/>
The purpose is to allow creating HTML5 apps that can interact with native code and use C/Obj-C libraries to perform any kind of actions.

Amaretto should work with OSX 10.7 Lion and higher.<br/>
The boilerplate uses XCode 5 and the OSX 10.9 Mavericks SDK.

## Starting up

This repository contains the Amaretto framework and a boilerplate you can use to create your own application. If you are interested only in the framework, please see below.

Start by checking out the repository:

```sh
git clone git@github.com:EgoAleSum/amaretto-osx.git
```

You can store your HTML5 app inside the _ui/_ folder. The only restriction is that the main file has to be called _index.html_.

## HTML5 -> Native

The HTML5 app can communicate with the native application by making a request. For example:

```js
Amaretto.request('method', {param1: 'val1', param2: 'val2'}, function(response) {
	if(response.error)
        // Error is inside response.errorString
    else
        // Content is inside response.data
})
```

`response` is a JavaScript object that contains three keys: `error` (a string or the integer 0 if everything is correct), `errorString` (human-readable description; empty if there was no error) and `data` (the payload).

There is also a synchronous version of `Amaretto.request`, which supports the same arguments: `Amaretto.syncRequest`.

Each method must be defined in the `Routes/Routes.plist` file. The key corresponds to the method, while the value must be the name of a class that implements the `AMRouteProtocol`.<br/>
An example can be seen in the file `AMExampleRoute` class.

## Native -> HTML5

Amaretto allows native apps to send messages to the HTML5 app. To do so, the HTML5 app first needs to register a callback that receives messages:

```js
Amaretto.setMainCallback(function(message) {
    // Perform some actions
})
```

This method can be executed from Cocoa by simply calling a method on `AMUIController`:

```objc
AMCommon *common = [AMCommon sharedInstance];
[common.UIController sendMessage:[NSDictionary dictionaryWithObject:@"value" forKey:@"key"]];
```

## Framework only

You can integrate the Amaretto framework into existing applications.

1. Include into your project the files contained into the `UIController` folder.
2. Create a `Routes.plist` file.
3. Link your application against the `WebKit` and `JavaScriptCore` frameworks.
4. Initialize the `AMUIController` object and connect it to a `WebView` in the interface (using the `mainWebView` outlet).
5. Eventually, call the `AMUIController.loadMainUI` method to load the HTML5 app.
