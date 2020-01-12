<template>
  <div>
    <h1>Form edit page</h1>
    <form-edit ref="formEdit" :entity="entity" @save="save">
    <label>
      Name:
      <input v-model="entity.name" />
    </label>
    <label>
      Email:
      <input type="email" v-model="entity.email" />
    </label>
  </form-edit>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator'
import FormEdit from '@/components/FormEdit.vue'
import { Route } from 'vue-router'

@Component({ components: { FormEdit } })
export default class Home extends Vue {
  public $refs!: {
    formEdit: FormEdit;
  };

  private entity: any = { name: '', email: '' };

  public mounted () {
    // At this point you would probably load some data and
    // update entity property. This will cause the FormEdit
    // to mark the entity as dirty
    this.entity = { name: 'user', email: 'user@mail.com' }

    // Because you know that this is indeed a clean state
    // you can force isDirty back to false to prevent
    // unwanted user prompting
    this.$refs.formEdit.resetDirty()
  }

  private save () {
    try {
      // Send data to server for saving or something similar
      // example below is purely for demo and won't work if uncommented
      // this.$http.post(entity);

      // at this point you know that your data is clean again
      // reset dirty and move on
      this.$refs.formEdit.resetDirty()
    } catch {
      // handle error
    }
  }

  /**
   * Vue Router hook that is called everytime a navigation occur away from this
   * component. This hook needs to be added to the registered component of a route
   * adding it to the FormEdit subcomponent will be ignored by Vue Router.
   */
  public beforeRouteLeave (
    to: Route,
    from: Route,
    next: (...args: any[]) => void
  ) {
    this.$refs.formEdit.ensureNotDirty(to, from, next)
  }
}
</script>

<style scoped>
label {
  display: block;
  margin: 10px;
}
</style>
