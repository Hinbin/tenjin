# frozen_string_literal: true

# SimpleForm wrappers built against the Tenjin design-system token classes
# (tjk-*) instead of Bootstrap 4 classes.  Bootstrap is still in the bundle
# during the 04c→04f migration, so both class sets exist simultaneously; the
# wrappers only emit tjk-* from here on.
#
# Wrapper naming mirrors the old Bootstrap equivalents so that any view that
# explicitly passes `wrapper:` keeps working without change.

SimpleForm.setup do |config|
  config.button_class = 'btn'
  config.boolean_label_class = 'tjk-check-label'

  config.label_text = lambda { |label, required, explicit_label| "#{label} #{required}" }
  config.boolean_style = :inline
  config.item_wrapper_tag = :div
  config.include_default_input_wrapper_class = false

  config.error_notification_class = 'tjk-alert-danger'
  config.error_method = :to_sentence

  config.input_field_error_class = 'tjk-input--invalid'
  config.input_field_valid_class = 'tjk-input--valid'


  # ── Vertical forms ────────────────────────────────────────────────────────

  config.wrappers :vertical_form,
                  tag: 'div', class: 'tjk-field',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: 'tjk-label'
    b.use :input, class: 'tjk-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
    b.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
    b.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
  end

  config.wrappers :vertical_boolean,
                  tag: 'fieldset', class: 'tjk-field',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.optional :readonly
    b.wrapper :form_check_wrapper, tag: 'div', class: 'tjk-check-wrap' do |bb|
      bb.use :input, class: 'tjk-check-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
      bb.use :label, class: 'tjk-check-label'
      bb.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
      bb.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
    end
  end

  config.wrappers :vertical_collection,
                  item_wrapper_class: 'tjk-check-wrap',
                  tag: 'fieldset', class: 'tjk-field',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.optional :readonly
    b.wrapper :legend_tag, tag: 'legend', class: 'tjk-label' do |ba|
      ba.use :label_text
    end
    b.use :input, class: 'tjk-check-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
    b.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
    b.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
  end

  config.wrappers :vertical_collection_inline,
                  item_wrapper_class: 'tjk-check-wrap tjk-check-wrap--inline',
                  tag: 'fieldset', class: 'tjk-field',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.optional :readonly
    b.wrapper :legend_tag, tag: 'legend', class: 'tjk-label' do |ba|
      ba.use :label_text
    end
    b.use :input, class: 'tjk-check-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
    b.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
    b.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
  end

  config.wrappers :vertical_file,
                  tag: 'div', class: 'tjk-field',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :readonly
    b.use :label, class: 'tjk-label'
    b.use :input, class: 'tjk-file-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
    b.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
    b.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
  end

  config.wrappers :vertical_multi_select,
                  tag: 'div', class: 'tjk-field',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.optional :readonly
    b.use :label, class: 'tjk-label'
    b.wrapper tag: 'div', class: 'tjk-multi-select-wrap' do |ba|
      ba.use :input, class: 'tjk-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
    end
    b.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
    b.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
  end

  config.wrappers :vertical_range,
                  tag: 'div', class: 'tjk-field',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :readonly
    b.optional :step
    b.use :label, class: 'tjk-label'
    b.use :input, class: 'tjk-range', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
    b.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
    b.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
  end


  # ── Horizontal forms ──────────────────────────────────────────────────────

  config.wrappers :horizontal_form,
                  tag: 'div', class: 'tjk-field tjk-field--horizontal',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: 'tjk-label tjk-label--horizontal'
    b.wrapper :grid_wrapper, tag: 'div', class: 'tjk-field__control' do |ba|
      ba.use :input, class: 'tjk-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
      ba.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
      ba.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
    end
  end

  config.wrappers :horizontal_boolean,
                  tag: 'div', class: 'tjk-field tjk-field--horizontal',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.optional :readonly
    b.wrapper tag: 'label', class: 'tjk-label tjk-label--horizontal' do |ba|
      ba.use :label_text
    end
    b.wrapper :grid_wrapper, tag: 'div', class: 'tjk-field__control' do |wr|
      wr.wrapper :form_check_wrapper, tag: 'div', class: 'tjk-check-wrap' do |bb|
        bb.use :input, class: 'tjk-check-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
        bb.use :label, class: 'tjk-check-label'
        bb.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
        bb.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
      end
    end
  end

  config.wrappers :horizontal_collection,
                  item_wrapper_class: 'tjk-check-wrap',
                  tag: 'div', class: 'tjk-field tjk-field--horizontal',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.optional :readonly
    b.use :label, class: 'tjk-label tjk-label--horizontal'
    b.wrapper :grid_wrapper, tag: 'div', class: 'tjk-field__control' do |ba|
      ba.use :input, class: 'tjk-check-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
      ba.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
      ba.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
    end
  end

  config.wrappers :horizontal_collection_inline,
                  item_wrapper_class: 'tjk-check-wrap tjk-check-wrap--inline',
                  tag: 'div', class: 'tjk-field tjk-field--horizontal',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.optional :readonly
    b.use :label, class: 'tjk-label tjk-label--horizontal'
    b.wrapper :grid_wrapper, tag: 'div', class: 'tjk-field__control' do |ba|
      ba.use :input, class: 'tjk-check-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
      ba.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
      ba.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
    end
  end

  config.wrappers :horizontal_file,
                  tag: 'div', class: 'tjk-field tjk-field--horizontal',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :readonly
    b.use :label, class: 'tjk-label tjk-label--horizontal'
    b.wrapper :grid_wrapper, tag: 'div', class: 'tjk-field__control' do |ba|
      ba.use :input, error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
      ba.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
      ba.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
    end
  end

  config.wrappers :horizontal_multi_select,
                  tag: 'div', class: 'tjk-field tjk-field--horizontal',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.optional :readonly
    b.use :label, class: 'tjk-label tjk-label--horizontal'
    b.wrapper :grid_wrapper, tag: 'div', class: 'tjk-field__control' do |ba|
      ba.wrapper tag: 'div', class: 'tjk-multi-select-wrap' do |bb|
        bb.use :input, class: 'tjk-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
      end
      ba.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
      ba.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
    end
  end

  config.wrappers :horizontal_range,
                  tag: 'div', class: 'tjk-field tjk-field--horizontal',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :readonly
    b.optional :step
    b.use :label, class: 'tjk-label tjk-label--horizontal'
    b.wrapper :grid_wrapper, tag: 'div', class: 'tjk-field__control' do |ba|
      ba.use :input, class: 'tjk-range', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
      ba.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
      ba.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
    end
  end


  # ── Inline forms ──────────────────────────────────────────────────────────

  config.wrappers :inline_form,
                  tag: 'span',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: 'sr-only'
    b.use :input, class: 'tjk-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
    b.use :error, wrap_with: { tag: 'div', class: 'tjk-error' }
    b.optional :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
  end

  config.wrappers :inline_boolean,
                  tag: 'span', class: 'tjk-check-wrap tjk-check-wrap--inline',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.optional :readonly
    b.use :input, class: 'tjk-check-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
    b.use :label, class: 'tjk-check-label'
    b.use :error, wrap_with: { tag: 'div', class: 'tjk-error' }
    b.optional :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
  end


  # ── Custom forms (formerly Bootstrap custom-control) ─────────────────────

  config.wrappers :custom_boolean,
                  tag: 'fieldset', class: 'tjk-field',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.optional :readonly
    b.wrapper :form_check_wrapper, tag: 'div', class: 'tjk-check-wrap' do |bb|
      bb.use :input, class: 'tjk-check-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
      bb.use :label, class: 'tjk-check-label'
      bb.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
      bb.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
    end
  end

  config.wrappers :custom_boolean_switch,
                  tag: 'fieldset', class: 'tjk-field',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.optional :readonly
    b.wrapper :form_check_wrapper, tag: 'div', class: 'tjk-switch-wrap' do |bb|
      bb.use :input, class: 'tjk-check-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
      bb.use :label, class: 'tjk-check-label'
      bb.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
      bb.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
    end
  end

  config.wrappers :custom_collection,
                  item_wrapper_class: 'tjk-check-wrap',
                  tag: 'fieldset', class: 'tjk-field',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.optional :readonly
    b.wrapper :legend_tag, tag: 'legend', class: 'tjk-label' do |ba|
      ba.use :label_text
    end
    b.use :input, class: 'tjk-check-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
    b.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
    b.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
  end

  config.wrappers :custom_collection_inline,
                  item_wrapper_class: 'tjk-check-wrap tjk-check-wrap--inline',
                  tag: 'fieldset', class: 'tjk-field',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.optional :readonly
    b.wrapper :legend_tag, tag: 'legend', class: 'tjk-label' do |ba|
      ba.use :label_text
    end
    b.use :input, class: 'tjk-check-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
    b.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
    b.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
  end

  config.wrappers :custom_file,
                  tag: 'div', class: 'tjk-field',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :readonly
    b.use :label, class: 'tjk-label'
    b.wrapper :custom_file_wrapper, tag: 'div', class: 'tjk-file-wrap' do |ba|
      ba.use :input, class: 'tjk-file-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
      ba.use :label, class: 'tjk-file-label'
      ba.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
    end
    b.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
  end

  config.wrappers :custom_multi_select,
                  tag: 'div', class: 'tjk-field',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.optional :readonly
    b.use :label, class: 'tjk-label'
    b.wrapper tag: 'div', class: 'tjk-multi-select-wrap' do |ba|
      ba.use :input, class: 'tjk-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
    end
    b.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
    b.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
  end

  config.wrappers :custom_range,
                  tag: 'div', class: 'tjk-field',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :readonly
    b.optional :step
    b.use :label, class: 'tjk-label'
    b.use :input, class: 'tjk-range', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
    b.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
    b.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
  end


  # ── Floating label forms ──────────────────────────────────────────────────

  config.wrappers :floating_labels_form,
                  tag: 'div', class: 'tjk-field tjk-field--floating',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :input, class: 'tjk-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
    b.use :label, class: 'tjk-label'
    b.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
    b.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
  end

  config.wrappers :floating_labels_select,
                  tag: 'div', class: 'tjk-field tjk-field--floating',
                  error_class: 'tjk-field--invalid', valid_class: 'tjk-field--valid' do |b|
    b.use :html5
    b.optional :readonly
    b.use :input, class: 'tjk-input', error_class: 'tjk-input--invalid', valid_class: 'tjk-input--valid'
    b.use :label, class: 'tjk-label'
    b.use :full_error, wrap_with: { tag: 'div', class: 'tjk-error' }
    b.use :hint, wrap_with: { tag: 'small', class: 'tjk-hint' }
  end


  # ── Defaults ──────────────────────────────────────────────────────────────

  config.default_wrapper = :vertical_form

  config.wrapper_mappings = {
    boolean:       :vertical_boolean,
    check_boxes:   :vertical_collection,
    date:          :vertical_multi_select,
    datetime:      :vertical_multi_select,
    file:          :vertical_file,
    radio_buttons: :vertical_collection,
    range:         :vertical_range,
    time:          :vertical_multi_select
  }
end
