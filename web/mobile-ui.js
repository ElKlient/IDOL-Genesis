/* Native Safari input owns text selection/paste. Godot owns license validation. */
(function () {
  class DriverMobileUI {
    static pixels(width, height, ratio) {
      const scale = Math.min(Math.max(ratio || 1, 1), 2);
      return {width:Math.max(1,Math.round(width*scale)),height:Math.max(1,Math.round(height*scale))};
    }
    constructor() {
      this.surface=document.getElementById('surface');
      this.canvas=document.getElementById('canvas');
      this.access=document.getElementById('access');
      this.form=document.getElementById('access-form');
      this.code=document.getElementById('access-code');
      this.message=document.getElementById('access-status');
      this.submit=document.getElementById('access-submit');
      this.refresh=document.getElementById('access-refresh');
      this.state=null;
      this.callback=null;
      this.frame=0;
      this.form.addEventListener('submit',event=>{
        event.preventDefault();
        if(this.submit.disabled||!this.callback)return;
        const code=this.code.value.trim();
        if(!code){this.message.textContent='Wpisz lub wklej kod od organizatora.';this.code.focus();return;}
        this.submit.disabled=true;
        this.code.blur();
        this.message.textContent='Sprawdzanie dostępu…';
        this.callback('activate',code);
      });
      this.refresh.addEventListener('click',()=>{if(this.callback&&!this.refresh.disabled)this.callback('refresh','');});
      document.getElementById('access-data').addEventListener('click',()=>{this.code.blur();this.access.hidden=true;});
      // Prevent only Godot's input listeners from seeing events originating in
      // this form. Do not preventDefault on paste, touch, selection or keydown.
      for(const type of ['keydown','keyup','paste','touchstart','touchend']){
        this.access.addEventListener(type,event=>event.stopPropagation());
      }
      this.resize=()=>{if(!this.frame)this.frame=requestAnimationFrame(()=>{this.frame=0;this.fit();});};
      addEventListener('resize',this.resize);
      window.visualViewport?.addEventListener('resize',this.resize);
      window.visualViewport?.addEventListener('scroll',this.resize);
      this.observer=new ResizeObserver(this.resize);this.observer.observe(this.surface);
      this.fit();
    }
    fit() {
      const view=window.visualViewport;
      const top=view?.offsetTop||0,left=view?.offsetLeft||0;
      const width=view?.width||innerWidth,height=view?.height||innerHeight;
      Object.assign(this.access.style,{top:`${top}px`,left:`${left}px`,width:`${width}px`,height:`${height}px`});
      this.surface.style.top=`calc(${top}px + env(safe-area-inset-top))`;
      this.surface.style.left=`calc(${left}px + env(safe-area-inset-left))`;
      this.surface.style.width=`calc(${width}px - env(safe-area-inset-left) - env(safe-area-inset-right))`;
      this.surface.style.height=`calc(${height}px - env(safe-area-inset-top) - env(safe-area-inset-bottom))`;
      const rect=this.canvas.getBoundingClientRect();
      const pixels=DriverMobileUI.pixels(rect.width,rect.height,devicePixelRatio);
      // Assigning an unchanged canvas dimension can clear/reset its rendering.
      if(this.canvas.width!==pixels.width)this.canvas.width=pixels.width;
      if(this.canvas.height!==pixels.height)this.canvas.height=pixels.height;
    }
    bind(callback){this.callback=callback;}
    show(){this.access.hidden=false;}
    update(value){
      const state=JSON.parse(value);
      if(!this.state||this.state.allowed!==state.allowed){this.access.hidden=state.allowed;}
      this.state=state;
      this.message.textContent=state.message;
      this.submit.disabled=state.busy||state.storage_error;
      this.refresh.hidden=!state.can_refresh;
      this.refresh.disabled=state.busy||state.storage_error;
      if(state.allowed){this.code.value='';this.code.blur();}
    }
  }
  window.DriverMobileUI=DriverMobileUI;
}());
