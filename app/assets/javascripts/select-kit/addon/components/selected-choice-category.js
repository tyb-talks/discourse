import SelectedChoiceComponent from "select-kit/components/selected-choice";
import { categoryBadgeHTML } from "discourse/helpers/category-link";
import { computed } from "@ember/object";
import { htmlSafe } from "@ember/template";

export default SelectedChoiceComponent.extend({
  tagName: "",
  extraClass: "selected-choice-category",

  badge: computed("item", function () {
    return htmlSafe(
      categoryBadgeHTML(this.item, {
        allowUncategorized: true,
        link: false,
      })
    );
  }),
});
