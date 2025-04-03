import haxe.io.Bytes;
import hxd.Pixels;
import h2d.col.IBounds;
import js.html.CanvasElement;
import js.lib.Uint8Array;
import js.html.Console;
import js.Browser;
import h3d.mat.Texture;
import h3d.scene.Object;
import h3d.prim.ModelCache;
import h3d.scene.Mesh;
import hxd.Key in K;

class Main extends hxd.App {
    var shadow :h3d.pass.DefaultShadowMap;
    var tf : h2d.Text;

    var obj : h3d.scene.Object;

    var s:Mesh;
    var s2:Object;

    var fui : h2d.Flow;

    override function init() {
        var light = new h3d.scene.fwd.DirLight(new h3d.Vector( 0.3, -0.4, -0.9), s3d);
        trace(light.enableSpecular = false);
        light.visible = false;

        // fully lit with ambient light of white?
        cast(s3d.lightSystem,h3d.scene.fwd.LightSystem).ambientLight.setColor(0xffffff);
        // cast(s3d.lightSystem,h3d.scene.fwd.LightSystem).ambientLight.setColor(0x909090);

        s3d.camera.target.set(0, 0, 0);
        s3d.camera.pos.set(120, 120, 40);

        // setting ortho bounds (needs a bunch more stuff for it to look right)
        // final bounds = new Bounds();
        // bounds.setMin(new Point(-100, -100, -100));
        // bounds.setMax(new Point(100, 100, 100));
        // s3d.camera.orthoBounds = bounds;

        final g = new h2d.Graphics(s2d);
        g.beginFill(0xff0000);
        g.drawRect(128, 128, 1, 128);
        g.drawRect(128, 128, 128, 1);
        g.drawRect(128 + 128, 128, 1, 128);
        g.drawRect(128, 128 + 128, 128, 1);
        g.endFill();
        // final boundsRect = new h2d.

        var cache = new h3d.prim.ModelCache();
        obj = cache.loadModel(hxd.Res.Model);
        // obj.scale(1 / 20);
        obj.rotate(0,0,Math.PI / 2);
        obj.y = 0.2;
        obj.z = 0.2;
        s3d.addChild(obj);
    
        trace(cache.loadAnimation(hxd.Res.Model));

        obj.playAnimation(cache.loadAnimation(hxd.Res.Model));

        shadow = s3d.renderer.getPass(h3d.pass.DefaultShadowMap);
        shadow.size = 2048;
        shadow.power = 200;
        shadow.blur.radius = 0.0;
        shadow.bias *= 0.1;
        shadow.color.set(0.7, 0.7, 0.7);

        s3d.camera.zNear = 1;
        s3d.camera.zFar = 100;
        new h3d.scene.CameraController(s3d).loadFromCamera();

        tf = new h2d.Text(hxd.res.DefaultFont.get(), s2d);

        fui = new h2d.Flow(s2d);
        fui.layout = Vertical;
        fui.verticalSpacing = 5;
        fui.padding = 10;

        // requires `dom` be commented out in h2d.Flow
        // addSlider("ax", function() return ax, function(x) { ax = x; }, 0, 6);
        // addSlider("ay", function() return ay, function(x) { ay = x; }, 0, 6);
        // addSlider("az", function() return az, function(x) { az = x; }, 0, 1000);
        // addSlider("angle", function() return angle, function(x) { angle = x; }, 0, Math.PI * 2);
        addCheck("light", function() return light.visible, function (x) { light.visible = x; });
        // addCheck("tex", function() return s.material == mat, function (x) { 
        //     s.material = x ? mat : mat2;
        // });
    }

    var prevPressed:Bool = false;

    override function update(dt:Float) {

        // TODO: justPressed
        final pressed = K.isPressed('S'.code);
        if (pressed && !prevPressed) {
            final width = 128;
            final height = 128;

            final numItems = 8;

            var s = hxd.Window.getInstance();

            var renderTexture = new h3d.mat.Texture(s.width, s.height, [h3d.mat.Data.TextureFlags.Target]);
            // s2d.render(engine);

            final pixelItems = [];
            for (_ in 0...numItems) {
                engine.pushTarget(renderTexture);
                s3d.render(engine);

                final bounds = new IBounds();
                bounds.set(128, 128, width, height);
                var pixels = renderTexture.capturePixels(0, 0, bounds);
                renderTexture.clearF(0, 0, 0, 0);

                trace(pixels.width, pixels.height);
                // pixels.sub(512, 512, width, height);
                // trace(pixels);
                engine.popTarget();

                pixelItems.push(pixels);

                obj.rotate(0, 0, Math.PI * 2 / numItems);
            }

            final pixels = new Pixels(width * numItems, height, Bytes.alloc(width * numItems * height * 4), RGBA);
            var i = 0;
            for (pi in pixelItems) {
                trace(i);
                pixels.blit(i * width, 0, pi, 0, 0, width, height);
                i++;
            }
#if js
            // create hidden canvas
            final canvas = cast(Browser.document.createElement('canvas'), CanvasElement);
            canvas.width = width * numItems;
            canvas.height = height;

            // add pixels to image and images to canvas
            final context = canvas.getContext2d();
            final image = context.createImageData(width * numItems, height);
            final data = new Uint8Array(pixels.bytes.getData());
            for (i in 0...data.byteLength) {
                image.data[i] = data[i];
            }
            context.putImageData(image, 0, 0);

            // link to download a element
            final link:Dynamic = Browser.document.createElement('a');
            link.href = canvas.toDataURL();
            link.download = 'f2.png';
            link.click();
#else
            // hxd.File.saveBytes("test.png", pixels.toPNG());
#end
        }
        prevPressed = pressed;

        tf.text = ""+engine.drawCalls;
    }

    static function main() {
        hxd.Res.initEmbed();
        new Main();
    }

    function addSlider( label : String, get : Void -> Float, set : Float -> Void, min : Float = 0., max : Float = 1. ) {
        var f = new h2d.Flow(fui);

        f.horizontalSpacing = 5;

        var tf = new h2d.Text(getFont(), f);
        tf.text = label;
        tf.maxWidth = 70;
        tf.textAlign = Right;

        var sli = new h2d.Slider(100, 10, f);
        sli.minValue = min;
        sli.maxValue = max;
        sli.value = get();

        var tf = new h2d.TextInput(getFont(), f);
        tf.text = "" + hxd.Math.fmt(sli.value);
        sli.onChange = function() {
            set(sli.value);
            tf.text = "" + hxd.Math.fmt(sli.value);
            f.needReflow = true;
        };
        tf.onChange = function() {
            var v = Std.parseFloat(tf.text);
            if( Math.isNaN(v) ) return;
            sli.value = v;
            set(v);
        };
        return sli;
    }
	function addCheck( label : String, get : Void -> Bool, set : Bool -> Void ) {
		var f = new h2d.Flow(fui);

		f.horizontalSpacing = 5;

		var tf = new h2d.Text(getFont(), f);
		tf.text = label;
		tf.maxWidth = 70;
		tf.textAlign = Right;

		var size = 10;
		var b = new h2d.Graphics(f);
		function redraw() {
			b.clear();
			b.beginFill(0x808080);
			b.drawRect(0, 0, size, size);
			b.beginFill(0);
			b.drawRect(1, 1, size-2, size-2);
			if( get() ) {
				b.beginFill(0xC0C0C0);
				b.drawRect(2, 2, size-4, size-4);
			}
		}
		var i = new h2d.Interactive(size, size, b);
		i.onClick = function(_) {
			set(!get());
			redraw();
		};
		redraw();
		return i;
	}
    function getFont() {
        return hxd.res.DefaultFont.get();
    }
}
