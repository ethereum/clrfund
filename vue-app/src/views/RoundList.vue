<template>
  <div class="rounds">
    <h1 class="content-heading">Rounds</h1>
    <div class="round" v-for="round in rounds" :key="round.index">
      <links
        v-if="round.address"
        class="round-name"
        :to="`/round/${round.address}`"
      >
        Round {{ round.index }}
      </links>
      <links v-else :to="round.url"> Round {{ round.index }} </links>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import Component from 'vue-class-component'
import { Watch } from 'vue-property-decorator'

import { Round, getRounds } from '@/api/rounds'
import Links from '@/components/Links.vue'

@Component({ components: { Links } })
export default class RoundList extends Vue {
  rounds: Round[] = []

  get factoryAddress(): string | undefined {
    return this.$store.state.currentFactoryAddress
  }

  created() {
    this.loadRounds()
  }

  @Watch('factoryAddress')
  async loadRounds() {
    if (this.factoryAddress) {
      this.rounds = (await getRounds(this.factoryAddress)).reverse()
    }
  }
}
</script>

<style scoped lang="scss">
@import '../styles/vars';

.content-heading {
  border-bottom: $border;
}

.round {
  background-color: $bg-secondary-color;
  border: $border;
  border-radius: 20px;
  box-sizing: border-box;
  margin-top: $content-space;
  padding: $content-space;

  a {
    color: $text-color;
    font-size: 16px;
  }
}
</style>
