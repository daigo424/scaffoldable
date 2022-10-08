# Scaffoldable

Railsのcontrollerの基本アクションの
index, show, create, update, new, edit, destroyを定義します。

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'scaffoldable', git: 'git@github.com:daigoishii/scaffoldable.git'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem specific_install git@github.com:daigoishii/scaffoldable.git scaffoldable
```

## Usage

`scaffoldable` を定義するだけで使えます。

```ruby
class PostsController < ApplicationController
  scaffoldable
end
```

カスタマイズ項目は以下（今後増えていきます）

※ 以下のモデルは、 https://github.com/makandra/active_type を使っています。

```ruby
class PostsController < ApplicationController
  scaffoldable(
    # 各アクションで使うモデルを指定できます。
    model: {
      new: Post::Editor,
      create: Post::Editor,
      edit: Post::Editor,
      update: Post::Editor
      # permitのクラスメソッドをそれぞれのモデルクラスに定義してください。
      #
      # 例) ---
      # class << self
      #   def permit_params
      #     %i[
      #       name
      #       code
      #     ]
      #   end
      # end
    },
    index: {
      order: -> { order(id: :desc) },
      where: -> { where(id: [1]) },
      paging: -> { page(c.params[:page]).per(3) },
      includes: -> { includes(:user) },
      references: -> { references(:users) }
      # etc.
      # order: [available: :desc, id: :desc]
      # includes: [:user]
      # references: [:users]
      # paging: { per: 3 }
    },
    create: {
      # #createの成功時のリダイレクト先を指定できます。
      succeeded_path: :index_path,
      succeeded_message: "登録しました。"
      # etc.
      # succeeded_path: proc { |c| index_path }
    },
    update: {
      # #updateの成功時のリダイレクト先を指定できます。
      succeeded_path: :index_path,
      succeeded_message: "更新しました。"
      # etc.
      # succeeded_path: -> { index_path }
    },
    destroy: {
      # #updateの成功時のリダイレクト先を指定できます。
      succeeded_path: :index_path,
      succeeded_message: "削除しました。"
      # etc.
      # succeeded_path: -> { index_path }
    }
  )
end
```

全体的に標準の設定をしたい場合は以下のように書きます。

```ruby
class ApplicationController < ActionController::Base
  scaffoldable_config(
    index: {
      order: [id: :desc]
    },
    create: {
      succeeded_path: :index_path
    },
    update: {
      succeeded_pathd: :index_path
    }
  )
end
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
