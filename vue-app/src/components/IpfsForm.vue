<template>
  <form method="POST" enctype="multipart/form-data" @submit="handleUploadToIPFS" name="image">
    <p class="input-label">{{ label }}</p>
    <p class="input-description"> {{description}} </p>
    <div class="input-row">
      <input
        id="image-upload"
        type="file"
        class="input"
        @change="handleLoadFile"
        name="image"
      />
      <button primary="true" type='submit' label='Upload' class="btn-primary" :class="{disabled: loading || error || !document}">
        {{ loading ? "Uploading..." : "Upload"}}
      </button>
    </div>
    <loader v-if="loading" />
    <div class="image-preview">
      <img
        v-if="data"
        :src="data"
        alt=""
        :class="{
          'image-preview': data,
        }"
      />
      <div style="display: flex; align-items: center; justify-content: center; width: 100%;">
        <div v-if="data" @click="handleRemoveImage" class="btn-white small">Remove image</div>
      </div>  
    </div>
    <div v-if="data" @click="copyHash" class="copy">
      <div class="label">
        IPFS hash <img width="16px" src="@/assets/info.svg" />
      </div>
      <div class="hash">
        <!-- {{ copied ? --> {{ hash }} <!-- : "Copied!"}} -->
        <img width="16px" src="@/assets/copy.svg" />
      </div>
    </div>
    <p v-if="error" class="error">{{ error }}</p>
  </form>
</template>

<script lang="ts">
import Vue from 'vue'
import Component from 'vue-class-component'
import { Prop } from 'vue-property-decorator'

import Loader from '@/components/Loader.vue'

import IPFS from 'ipfs-mini'

@Component({
  components: { Loader },
})
export default class IpfsForm extends Vue {
  @Prop() label!: string
  @Prop() description!: string
  @Prop() formProp!: string
  @Prop() onUpload!: (key: string, value: string) => void

  hash = ''
  loading = false
  data = ''
  document = ''
  error = ''
  ipfs: any = null

  created() {
    this.ipfs = new IPFS({ host: 'ipfs.infura.io', port: 5001, protocol: 'https' })
  }

  // TODO raise error if not valid image (JPG / PNG / GIF)
  handleLoadFile(event) {
    this.error = ''
    const data = event.target.files[0]
    if (data.type.match('image/*')) {
      const reader = new FileReader()
      reader.onload = (() => ((e) => {this.document = e.target.result}))()
      reader.readAsDataURL(data)
    } else {
      this.error = 'That doesn\'t look like an image'
    }
  }

  // TODO display error in UI
  handleUploadToIPFS(event) {
    event.preventDefault()

    if (this.document !== '') {
      this.loading = true
      this.ipfs.addJSON(this.document, async (err, _hash) => {
        if (!err) {
          this.hash = _hash
          this.ipfs.catJSON(this.hash, async (err2, data) => {
            if (!err2) {
              this.data = data
              this.onUpload(this.formProp, this.hash)

            } else {
              this.error = `Error occured: ${err2.message}`
            }
            this.loading = false
          })
        } else {
          this.loading = false
          this.error = 'Error occured: ${err.message}'
        }
      })
    } else {
      this.error = 'You need an image.'
    }
  }

  handleRemoveImage(): void {
    this.hash = ''
    this.loading = false
    this.data = ''
    this.document = ''
    this.error = ''
    this.onUpload(this.formProp, '')
  }

  async copyHash(): Promise<void> {
    try {
      await navigator.clipboard.writeText(this.hash)
      // TODO: UX success feedback
    } catch (error) {
      console.warn('Error in copying text: ', error) /* eslint-disable-line no-console */
    }
  }
}
</script>

<style scoped lang="scss">
@import "../styles/vars";
@import "../styles/theme";

.image-preview {
  width: 100%;
  height: auto;
  display: flex;
  align-items: center;
  background: $bg-secondary-color;
  box-shadow: $box-shadow;
  border-radius: 8px;
  @media (max-width: $breakpoint-m) {
    flex-direction: column;
  }
}

.image-preview img {
  width: 50%;
  @media (max-width: $breakpoint-m) {
    width: 100%;
  }
}

.disabled {
  cursor: not-allowed;
  opacity: 0.5;

  &:hover {
    opacity: 0.5;
    transform: scale(1);
    cursor: not-allowed;
  }  
}

.btn-white.small {
/*   max-width: calc(5ch + 4rem); */
color: $error-color;
border: 2px solid $error-color;
@media (max-width: $breakpoint-m) {
    margin: 1rem;
  }
}

.input-row {
  display: flex;
  gap: 1rem;
  @media (max-width: $breakpoint-m) {
    flex-direction: column;
  }
  margin: 1rem 0 2rem;
}

.input {
  flex: 1;
  margin: 0;
}

.copy {
  border: 1px solid #fff;
  border-radius: 0.5rem;
  background: $bg-secondary-color;
  margin-top: 2rem;
  display: flex;
  width: fit-content;
  cursor: pointer;
  &:hover {
    background: $bg-light-color;
  }
  @media (max-width: $breakpoint-m) {
    flex-direction: column;
    width: 100%;
  }
  

.label {
  background: $bg-primary-color;
  padding: 0.5rem;
  text-transform: uppercase;
  font-size: 16px;
  font-family: "Glacial Indifference", sans-serif;
  border-radius: 0.5rem 0 0 0.5rem;
  border-right: 1px solid #fff;
  line-height: 150%;
  display: flex;
  align-items: center;
  gap: 0.25rem;
  @media (max-width: $breakpoint-m) {
    border-radius: 0.5rem 0.5rem 0 0;
    border-right: 0;
  }
}

.label img {
  padding: 0.25rem;
  border-radius: 4px;
  &:hover {
    background: $bg-light-color;
  }
}

.hash {
  padding: 0.5rem;
  font-family: monospace;
  line-height: 150%;
  display: flex;
  align-items: center;
  gap: 1rem;
  flex-wrap: wrap;
}

.hash img {
  padding: 0.25rem;
  border-radius: 4px;
  &:hover {
    background: $bg-primary-color;
  }
}

}
</style>