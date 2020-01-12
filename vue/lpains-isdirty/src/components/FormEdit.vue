<template>
  <div>
    <div>
      <label>status: {{isDirty ? "dirty" : "clean"}}</label>
    </div>
    <slot></slot>
    <div>
      <button @click.prevent="$emit('save')">save</button>
    </div>
    <sweet-modal ref="warningModal">
      <div>You are going to lose your changes. Are you sure?</div>
      <div class="modalButtons">
        <button @click.prevent="discardChanges">Discard Changes</button>
        <button @click.prevent="cancelNavigation">Cancel</button>
      </div>
    </sweet-modal>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue, Watch } from 'vue-property-decorator'
import { SweetModal } from 'sweet-modal-vue'
import Entity from './entity'
import { Route } from 'vue-router'

@Component({ components: { SweetModal } })
export default class FormEdit extends Vue {
  @Prop()
  private entity?: Entity;

  private isDirty?: boolean = false;
  private navigatingTo?: Route;

  public $refs!: {
    warningModal: any;
  };

  /**
   * Gives control of the dirty flag. If method consumer deems form to be clean. It
   * can be reset using this method.
   */
  public resetDirty () {
    this.$nextTick(() => {
      this.isDirty = false
    })
  }

  /**
   * Checks of form is dirty, stops navigation and prompts user for confirmation
   */
  public ensureNotDirty (
    to: Route,
    from: Route,
    next: (...args: any[]) => void
  ) {
    if (!this.isDirty) {
      next()
    } else {
      this.navigatingTo = to

      next(false)

      this.$refs.warningModal.open()
    }
  }

  @Watch('entity', { deep: true })
  private onEntityChanged (newValue: any) {
    // every time the entity property or any inner property changes
    // set dirty to true
    // this can be further improved to store an original object
    // and then compare to it. If the user undoes the changes
    // it goes back to clean. Maybe using a toJson?
    this.isDirty = true
  }

  private async discardChanges () {
    // mark the object as clean so navigation is allowed
    this.isDirty = false

    // ensure you have a route to navigate to
    if (!this.navigatingTo) {
      return
    }

    this.$refs.warningModal.close()

    // push the original route before the prompt was shwon
    await this.$router.push(this.navigatingTo.path)
  }

  private cancelNavigation () {
    this.$refs.warningModal.close()
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
.modalButtons {
  margin-top: 30px;
}
.modalButtons button {
  margin: 10px;
}
</style>
