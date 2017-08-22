package;

import kha.Assets;
import kha.System;

class Main 
{
    public static var width:Int = 800;
    public static var height:Int = 600;
    
    public static function main():Void
    {
        System.init({title: "Project", width: width, height: height}, function () 
        {
            Assets.loadEverything(function():Void
            {
                new Project();
            });
        });
    }
}
