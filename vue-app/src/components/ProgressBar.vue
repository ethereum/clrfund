<template>
  <div class="progress-bar" :style="progressBarStyle">
    <div v-for="idx in totalSteps" :key="idx">
      <div class="step" :class="{ inactive: isFutureStep(idx) }" />
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import Component from 'vue-class-component'
import { Prop } from 'vue-property-decorator'

@Component
export default class Transaction extends Vue {
  @Prop()
  currentStep!: number

  @Prop()
  totalSteps!: number

  get progressBarStyle(): string {
    return `grid-template-columns: repeat(${this.totalSteps}, 1fr);`
  }
  isFutureStep(step: number): boolean {
    return step > this.currentStep
  }
}
</script>

<style scoped lang="scss">
@import '../styles/vars';

.progress-bar {
  display: grid;
  column-gap: 0.5rem;
}

.step {
  background: $clr-pink-light-gradient;
  height: 8px;
  width: 100%;
  border-radius: 32px;
}

.inactive {
  background: $clr-pink-light-gradient-inactive;
}
</style>
