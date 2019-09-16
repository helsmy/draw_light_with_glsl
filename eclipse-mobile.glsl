#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

// 参考 https://zhuanlan.zhihu.com/p/71601799
// 以及 https://zhuanlan.zhihu.com/p/71300686
// 这个版本的连接，不要嫌弃我的菜代码
// https://github.com/helsmy/draw_light_with_glsl

uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;
uniform int pointerCount;
uniform vec3 pointers[10];

float circle(in vec2 _st, in float _radius){
    vec2 dist = _st-vec2(0.5);
  return 1.-smoothstep(_radius-(_radius*0.02),
                         _radius-(_radius*0.01),
                         dot(dist,dist)*4.0);
}

float rand (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))
                 * 43758.5453123);
}

vec3 star(vec2 pos, vec2 mpos, vec2 sunpos){
    vec3 light = vec3(step(rand(pos*999.0), 0.0));
    float lm = distance(mpos, sunpos);
    if (distance(mpos, pos) < 0.09){
      return vec3(0.0);}
    if (lm < 0.5){
        return pow(1.0-lm/0.5, 3.0)*(light);}
    return vec3(0.0);
}

vec2 rayIntersectSphere(vec3 rayStart, vec3 rayDir, vec3 c, float r)
//
//ref: https://en.wikipedia.org/wiki/Line%E2%80%93sphere_intersection
//
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
    // 这个应该可以直接写在求交的函数里面
    inter_point = max(vec2(0.0), inter_point);

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
    //
    float attenFac = 1.0/(40.0*max(0.01, dot(pos, pos)));
    return light*attenFac;
}

vec3 sky(vec2 pos, vec2 mpos, vec3 day,vec3 night, vec3 sunColor, float sun_r, float moon_r){
    // 绘制天空太阳和月亮
    float lm = distance(vec2(0.0),mpos);
    if (distance(pos, mpos) < moon_r)
        return vec3(0.0);
    if (distance(pos, vec2(0,0)) < sun_r)
        return 1.0-sunColor*circle(vec2(0.0),0.09);
    if (lm < 0.5)
        //
        return clamp(night, day,
                    vec3(lm / 0.5));
    return day;
}

void main(){
    float mx = max(resolution.x, resolution.y);
    vec2 st = gl_FragCoord.xy / mx;
    //float aspect = resolution.x/resolution.y;
    //st *= aspect;
    //vec2 mpos = vec2(0.31, 0.52);
    vec2 mpos = max(vec2(0.0), pointers[0].xy/mx);
/*
    不会写多点触控的支持，现在就只支持一个了
    for (int n = 0; n < pointerCount; ++n) {
        mpos = max(pointers[n].xy/mx,
                   mpos);
  }
*/

    vec3 day = vec3(0.2,0.3,0.5);
    vec3 night = vec3(0.1,0.1,0.1);

    //这个溢出值可以让太阳在最后的时候显得黄一点
    vec3 sunColor = vec3(1.2,1.1,1.0);
    vec3 mooncolor = vec3(0.0);
    vec2 sunpos = vec2(0.0);
    float sun_r = 0.09;
    float moon_r = 0.09;
    mpos = mpos - vec2(0.28125,0.5);
    vec2 pos = st-vec2(0.28125,0.5);
/*
    不会自动配适分辨率，来个大神教我 OTZ
    float shortl = min(resolution.x, resolution.y);
    float longl = max(resolution.x, resolution.y);
    float scale = shortl/longl;
    pos.y = pos.y / scale;
*/

    vec3 skycolor = sky(pos, mpos, day, night, 
                        sunColor, sun_r, moon_r);
    vec3 light = godray(pos, sunpos, mpos, 
                        sun_r, moon_r, 
                        skycolor, sunColor, mooncolor);
    vec3 starlight = star(pos, mpos, sunpos);
    vec3 color = skycolor + light + starlight;

    gl_FragColor = vec4( color, 1.0 );
}
