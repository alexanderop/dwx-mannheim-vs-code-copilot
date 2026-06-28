<template>
  <div class="xd">
    <div class="row">
      <div class="xd-box b1" v-click="1">
        <div class="t">LLM</div>
        <div class="s">just a text<br>generator</div>
      </div>

      <div class="op" v-click="2">+</div>

      <div class="xd-box b2" v-click="2">
        <div class="t">Tools</div>
        <div class="s">read news,<br>call APIs,<br>edit files</div>
      </div>

      <div class="op" v-click="3">+</div>

      <div class="xd-box b3" v-click="3">
        <div class="t">Agentic Loop</div>
        <div class="s">think → act →<br>observe → repeat</div>
      </div>

      <div class="op eq" v-click="4">=</div>

      <div class="xd-box b4" v-click="4">
        <div class="t">🤖 Agent</div>
        <div class="s">interacts with<br>the world</div>
      </div>
    </div>

    <div class="caption" v-click="5">
      An LLM can only <em>talk</em>. Give it tools + a loop, and it can <em>do</em>.
    </div>
  </div>
</template>

<style scoped>
.xd { margin-top: 2.2rem; font-family: 'Caveat', 'Comic Sans MS', cursive; }
.row {
  display: flex; align-items: center; justify-content: center; gap: 1.1rem;
}
.xd-box {
  border: 2.5px solid #fff;
  border-radius: 255px 15px 225px 15px / 15px 225px 15px 255px;
  padding: 1rem 1.3rem; text-align: center; min-width: 130px;
  background: rgba(255,255,255,0.02);
}
.xd-box .t { font-size: 1.9rem; font-weight: 700; line-height: 1; }
.xd-box .s { font-size: 1.15rem; opacity: 0.75; margin-top: 0.45rem; line-height: 1.1; }
.b1 { transform: rotate(-1deg); }
.b2 { transform: rotate(1deg); border-color: #ff6bed; }
.b3 { transform: rotate(-1.2deg); border-color: #ff6bed; }
.b4 {
  transform: rotate(0.8deg); border-color: #ff6bed;
  box-shadow: 0 0 0 4px rgba(255,107,237,0.12);
}
.b4 .t { color: #ff6bed; }
.op { font-size: 2.6rem; font-weight: 700; opacity: 0.85; }
.op.eq { color: #ff6bed; }
.caption {
  margin-top: 2.4rem; text-align: center; font-size: 1.7rem; opacity: 0.85;
}
.caption em { color: #ff6bed; font-style: normal; }
</style>
