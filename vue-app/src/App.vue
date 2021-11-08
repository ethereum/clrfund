<template>
  <router-view :key="$route.params.factoryAddress" />
</template>

<script lang="ts">
import Vue from 'vue'
import Component from 'vue-class-component'

@Component
export default class App extends Vue {}
</script>

<style scoped lang="scss">
@import 'styles/vars';
@import 'styles/theme';
</style>
