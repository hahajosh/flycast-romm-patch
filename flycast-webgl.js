//!FLYCAST PATCH!
//adds context functions called by the flycast module to handle web gl specific issues with the flycast core.
if (window.EJS_core == "flycast") {
    const origGetContext = HTMLCanvasElement.prototype.getContext;
    HTMLCanvasElement.prototype.getContext = function (type, attrs) {
        const ctx = origGetContext.call(this, type, attrs);
        if (ctx && (type === "webgl2" || type === "experimental-webgl2") && !ctx.__flycastPatched) {
            ctx.__flycastPatched = true;

            const origGetParam = ctx.getParameter.bind(ctx);
            ctx.getParameter = function (pname) {
                if (pname === 0x1f02 || pname === ctx.VERSION) {
                return "OpenGL ES 3.0 WebGL 2.0";
                }
                if (pname === 0x8b8c || pname === ctx.SHADING_LANGUAGE_VERSION) {
                return "OpenGL ES GLSL ES 3.00";
                }
                return origGetParam(pname);
            };

            const origGetError = ctx.getError.bind(ctx);
            ctx.getError = function () {
                let err = origGetError();
                while (err === 0x500) err = origGetError();
                return err;
            };

            const texBindings = {};
            texBindings[ctx.TEXTURE_2D] = ctx.TEXTURE_BINDING_2D;
            texBindings[ctx.TEXTURE_CUBE_MAP] = ctx.TEXTURE_BINDING_CUBE_MAP;
            if (ctx.TEXTURE_3D) texBindings[ctx.TEXTURE_3D] = ctx.TEXTURE_BINDING_3D;
            if (ctx.TEXTURE_2D_ARRAY) texBindings[ctx.TEXTURE_2D_ARRAY] = ctx.TEXTURE_BINDING_2D_ARRAY;

            const origTexParameteri = ctx.texParameteri.bind(ctx);
            ctx.texParameteri = function (target, pname, param) {
                const b = texBindings[target];
                if (b && !origGetParam(b)) return;
                return origTexParameteri(target, pname, param);
            };

            const origTexParameterf = ctx.texParameterf.bind(ctx);
            ctx.texParameterf = function (target, pname, param) {
                const b = texBindings[target];
                if (b && !origGetParam(b)) return;
                return origTexParameterf(target, pname, param);
            };

            // Rewrite #version 130 -> #version 300 es
            const origShaderSource = ctx.shaderSource.bind(ctx);
            ctx.shaderSource = function (shader, source) {
                if (typeof source === "string" && source.indexOf("#version 130") !== -1) {
                source = source.replace(/#version 130/g, "#version 300 es");
                }
                return origShaderSource(shader, source);
            };

            // GL_RED (0x1903) -> GL_R8 (0x8229) for texImage2D internalformat
            const origTexImage2D = ctx.texImage2D.bind(ctx);
            ctx.texImage2D = function (...args) {
                if (args.length >= 3 && args[2] === 0x1903) args[2] = 0x8229;
                return origTexImage2D.apply(null, args);
            };

            // Fallback shader on compile failure instead of letting the core abort()
            const origCompileShader = ctx.compileShader.bind(ctx);
            ctx.compileShader = function (shader) {
                origCompileShader(shader);
                if (!ctx.getShaderParameter(shader, ctx.COMPILE_STATUS)) {
                const log = ctx.getShaderInfoLog(shader);
                const type = ctx.getShaderParameter(shader, ctx.SHADER_TYPE);
                console.warn("[flycast] shader compile failed, substituting fallback:", log);
                const fallback =
                    type === ctx.VERTEX_SHADER
                    ? "#version 300 es\nin vec3 VertexCoord;\nvoid main(){gl_Position=vec4(0.0);}\n"
                    : "#version 300 es\nprecision mediump float;\nout vec4 FragColor;\nvoid main(){FragColor=vec4(0.0);}\n";
                origShaderSource(shader, fallback);
                origCompileShader(shader);
                }
            };

            const origEnable = ctx.enable;
            ctx.enable = function (cap) {
                //console.log("glEnable:", "0x" + cap.toString(16));
                return origEnable.call(this, cap);
            };

            const origDisable = ctx.disable;
            ctx.disable = function (cap) {
                //console.log("glDisable:", "0x" + cap.toString(16));
                return origDisable.call(this, cap);
            };
        }
        return ctx;
    };
}
