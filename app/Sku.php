<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Sku extends Model
{
        protected $fillable = ['size'];
        protected $table = 'skus';

        public function product()
            {
                return $this->belongsTo('App\Product')->withTimestamps();
            }
}
