#ifdef GL_FRAGMENT_HIGH
precision highp float;
#else
precision mediump float;
#endif

#define PI 3.14159265359
#define TWO_PI 6.28318530718
#define N 64

uniform vec2 u_resolution;

float NLength(vec2 pos, vec3 lightpos){
    return 2.0*asin(lightpos.z/
                    distance(pos, vec2(lightpos.x, lightpos.y))
                   ); 
}

bool inCircle(vec2 pos, vec3 lightpos){
    // 和 pos 距离 圆心 比 圆的半径 小 等同
    return bool(step(distance(pos, vec2(lightpos.x, lightpos.y)), 
                     lightpos.z
                    )
               );
}

vec3 Lsimple(vec2 pos, vec3 lightpos, float emission){
    vec3 color = vec3(1.0, 1.0, 1.0);
    float temp = 0.0;
    if (!inCircle(pos, lightpos)){
        temp = NLength(pos, lightpos) / TWO_PI * emission;
    	color = vec3(temp);
    }  
    else
        color = vec3(1.0);
    return color;
}

void main(){
    vec2 st = gl_FragCoord.xy / u_resolution.xy;
    
    // 将原点置于画面中心
    vec2 pos = vec2(0.5) - st;
    
    // vec3 lightpos: x,y 光源坐标, z: 光源半径
    vec3 lightpos = vec3(0.0,0.0,0.1);
	  vec3 color = Lsimple(pos, lightpos, 2.000);
    
    gl_FragColor = vec4(color, 1.0);
}
