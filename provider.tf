terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.149.0"
    }
  }
}

provider "yandex" {
  token     = "$yc iam create-token"   # САМ ВСТАВЛЯЕШЬ СЮДА СВОЙ ТОКЕН ДЛИННЫЙ 
  folder_id = "b1g2dh5hul1tiuhpl1bk"
  zone      = "ru-central1-b"
}
