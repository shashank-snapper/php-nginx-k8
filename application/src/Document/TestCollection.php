<?php

namespace App\Document;

use Doctrine\ODM\MongoDB\Mapping\Annotations as ODM;


#[ODM\Document]
class TestCollection
{
    #[ODM\Id()]
    public string $id;

    #[ODM\Field(type: "date")]
    public ?\DateTime $timestamp;

}