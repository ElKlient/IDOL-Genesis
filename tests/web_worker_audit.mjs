import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';

function fixture(fail=false) {
  const handlers={},removed=[],network=[];let waited;
  const scope='https://calendar.test/iphone/service-worker.js';
  const cache={addAll:async()=>{if(fail)throw Error('offline');},match:async url=>new Response('saved:'+url)};
  const source=readFileSync(new URL('../web/service-worker.js',import.meta.url),'utf8').replace('__BUILD__','new').replace('__FILES__',JSON.stringify(['index.html','index.pck','/api/web-assets/'+'a'.repeat(64)+'/index.wasm']));
  vm.runInNewContext(source,{self:{location:new URL(scope),addEventListener:(name,fn)=>handlers[name]=fn,clients:{claim:async()=>{}}},caches:{open:async()=>cache,keys:async()=>['driver-calendar-web-old','driver-calendar-web-new','other-app-cache'],delete:async name=>removed.push(name)},fetch:async request=>{network.push(request.url);return new Response('network');},Response,URL});
  return {handlers,removed,network,event:()=>({waitUntil:p=>{waited=p}}),wait:()=>waited};
}

test('A failed download cannot install a partial replacement',async()=>{
  const f=fixture(true);f.handlers.install(f.event());await assert.rejects(f.wait());assert.deepEqual(f.removed,[]);
});
test('Activation removes only obsolete application caches',async()=>{
  const f=fixture();f.handlers.activate(f.event());await f.wait();assert.deepEqual(f.removed,['driver-calendar-web-old']);
});
test('Offline navigation uses the saved app, while activation and admin remain uncached',async()=>{
  const f=fixture();let answer;
  f.handlers.fetch({request:{url:'https://calendar.test/iphone/',method:'GET',mode:'navigate'},respondWith:p=>answer=p});
  assert.equal(await(await answer).text(),'saved:https://calendar.test/iphone/index.html');
  for(const [method,url] of [['POST','/api/beta/activate'],['GET','/api/admin/licenses'],['GET','/api/releases/latest']]) {
    f.handlers.fetch({request:{url:'https://calendar.test'+url,method,mode:'cors'},respondWith:()=>assert.fail('Private API response must not be cached')});
  }
  assert.deepEqual(f.network,[]);
});
