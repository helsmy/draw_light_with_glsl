#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;

float circle(in vec2 _st, in float _radius){
    vec2 dist = _st-vec2(0.5);
	return 1.-smoothstep(_radius-(_radius*0.01),
                         _radius+(_radius*0.01),
                         dot(dist,dist)*4.0);
}

float rand (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))
                 * 43758.5453123);
}

vec3 star(vec2 pos, vec2 mpos, vec2 sunpos){
    vec3 light = vec3(step(rand(pos), 0.0));
    float lm = distance(mpos, sunpos);
    if (lm < 0.5){
        // 不知道为什么clmap不行，强行变成个小数乘在light前了
        // 次数愈大变化越陡峭
        return pow(1.0-lm/0.5, 3.0)*(light);
    }
    return vec3(0.0);
}

vec2 rayIntersectSphere(vec3 rayStart, vec3 rayDir, vec3 c, float r)
//直线与球体求交，退化使用可用于直线与圆求交
//ref: https://en.wikipedia.org/wiki/Line%E2%80%93sphere_intersection
//抄的 反正这个基本都是抄的
{
	vec3 l = rayDir;
	vec3 o = rayStart;
	float A = dot(l, o - c);
	float B = dot(o - c, o - c);
	float C = A * A - (B - r * r);
	if (C < 0.0) {
		return vec2(1000,1000);//infinity
	}
	else {
		float sqrtC = sqrt(C);
		vec2 d = vec2(-A - sqrtC,-A+sqrtC);
		return d;
	}
}

vec3 godray(vec2 pos, vec2 sunpos, vec2 mpos, float sun_r,float moon_r, vec3 skyColor, vec3 sunColor, vec3 moonColor){
    vec3 light = vec3(0.0);
    float sunCoverButMoonNotCoverLength = 0.0;
    float moonCoverLength = 0.0;
    float Length =distance(pos,sunpos);
    vec2 dir = normalize(pos-sunpos);
    
    vec2 inter_point = rayIntersectSphere(vec3(sunpos,1.0), vec3(dir,1.0),
                                          vec3(mpos,1.0), moon_r);
    // 舍去负解，平方的方程负解在moon位置的正对面也会产生阴影
    inter_point = max(vec2(0.0), inter_point);
    // moon在sun之外的时候用sun的半径，
    // moon在sun之内的时候有重叠就用二者之间距离
    float rmin = min(Length, sun_r);
    if(inter_point.x > rmin){
        sunCoverButMoonNotCoverLength = rmin;
    }
    else{
        if(inter_point.y > rmin){
            sunCoverButMoonNotCoverLength = inter_point.x;
        }
        else{
            sunCoverButMoonNotCoverLength = rmin - (inter_point.y - inter_point.x);
        }
    }
    if (inter_point.x > Length){
        moonCoverLength = 0.0;
    }
    else{
        if (inter_point.y > Length) {
            moonCoverLength = Length - inter_point.x;
        }
        else{
            moonCoverLength = inter_point.y - inter_point.x;
        }
    }
    float skyCoverLength = Length - sunCoverButMoonNotCoverLength - moonCoverLength;
    light = (skyCoverLength * skyColor +
             sunCoverButMoonNotCoverLength * sunColor +
             moonCoverLength * moonColor)/Length;
    // 所以为什么这个衰减系数乘上之后会光晕也有了呢？
    float attenFac = 1.0/(40.0*max(0.01, dot(pos, pos)));
    return light*attenFac;
}

vec3 sky(vec2 pos, vec2 mpos, vec3 day,vec3 night, vec3 sunColor){
    // 绘制天空太阳和月亮
    float lm = distance(vec2(0.0),mpos);
    if (distance(pos, mpos) < 0.09)
        return vec3(0.0);
    if (distance(pos, vec2(0,0)) < 0.09)
        return sunColor;
    if (lm < 0.5)
        //昼夜变化的过渡
        return clamp(night, day,
                    vec3(lm / 0.5));
    return day;
}

void main(){
	vec2 st = gl_FragCoord.xy/resolution.xy;
    vec2 mpos = mouse/resolution;
    vec3 day = vec3(0.2,0.3,0.5);
    vec3 night = vec3(0.1,0.1,0.1);
    //这个溢出值可以让太阳在最后的时候显得黄一点
    vec3 sunColor = vec3(1.2,1.1,1.0);
    vec3 mooncolor = vec3(0.0);
    vec2 sunpos = vec2(0.0);
    float sun_r = 0.09;
    float moon_r = 0.09;
    mpos = mpos - vec2(0.5);
    vec2 pos = st - vec2(0.5);

    vec3 skycolor = sky(pos, mpos, day, night, sunColor);
    vec3 light = godray(pos, sunpos, mpos, sun_r, moon_r, skycolor, sunColor, mooncolor);
    vec3 starlight = star(pos, mpos, sunpos);
    vec3 color = skycolor + light + starlight;
    
	gl_FragColor = vec4( color, 1.0 );
}
